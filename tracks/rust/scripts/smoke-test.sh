#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

export TEMPORAL_ADDRESS="${TEMPORAL_ADDRESS:-127.0.0.1:7233}"
STARTED_SERVER=""
STARTED_ADNET=""
WORKER_PID=""

cleanup() {
  [ -z "$WORKER_PID" ] || kill "$WORKER_PID" 2>/dev/null || true
  [ -z "$STARTED_SERVER" ] || kill "$STARTED_SERVER" 2>/dev/null || true
  [ -z "$STARTED_ADNET" ] || kill "$STARTED_ADNET" 2>/dev/null || true
}
trap cleanup EXIT

fail() { echo "SMOKE FAIL: $1" >&2; exit 1; }

# Start a solution Worker binary and wait until it is polling.
run_worker() {
  local bin="$1"
  local log="/tmp/rust-worker-$bin.log"
  cargo run -q --bin "$bin" >"$log" 2>&1 &
  WORKER_PID=$!
  for _ in $(seq 1 120); do
    grep -q "Worker started" "$log" 2>/dev/null && return 0
    kill -0 "$WORKER_PID" 2>/dev/null || fail "worker $bin exited (see $log)"
    sleep 1
  done
  fail "worker $bin did not start (see $log)"
}

stop_worker() {
  [ -z "$WORKER_PID" ] || kill "$WORKER_PID" 2>/dev/null || true
  wait "$WORKER_PID" 2>/dev/null || true
  WORKER_PID=""
}

result_of() {
  temporal workflow show -w "$1" -o json |
    jq -r '[.events[] | select(.workflowExecutionCompletedEventAttributes != null)][0].workflowExecutionCompletedEventAttributes.result.payloads[0].data' |
    base64 -d
}

max_attempt_of() {
  temporal workflow show -w "$1" -o json |
    jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
}

echo "==> static checks"
cargo build --locked --bins

echo "==> services"
if ! temporal operator cluster health >/dev/null 2>&1; then
  smoke_db="$(mktemp -d)/temporal.db"
  temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --headless \
    --db-filename "$smoke_db" >/tmp/rust-temporal.log 2>&1 &
  STARTED_SERVER=$!
  for _ in $(seq 1 30); do
    temporal operator cluster health >/dev/null 2>&1 && break
    sleep 1
  done
fi
temporal operator cluster health >/dev/null || fail "dev server did not start"

if ! curl -sf localhost:9999/health >/dev/null 2>&1; then
  .adnet-venv/bin/python services/adnet.py >/tmp/rust-adnet.log 2>&1 &
  STARTED_ADNET=$!
  sleep 2
fi
curl -sf localhost:9999/health >/dev/null || fail "AdNet did not start"

echo "==> exercise 01"
curl -sf -X POST localhost:9999/chaos/on >/dev/null
if cargo run -q --bin campaign-app >/dev/null 2>&1; then
  fail "fragile app should fail while chaos is on"
fi

echo "==> exercise 02"
run_worker tagline-worker-solution
temporal workflow execute --type TaglineWorkflow --task-queue tagline-tasks \
  -w smoke-rust-tagline --input '"CatNip Cola"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-rust-tagline | grep -q "CatNip Cola: Taste the Meow!" || fail "exercise 02 result"
stop_worker

echo "==> exercise 03"
run_worker social-post-worker-solution
temporal workflow execute --type SocialPostWorkflow --task-queue social-tasks \
  -w smoke-rust-social --input '"catstagram"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-rust-social | grep -q "#CatsOfCatstagram" || fail "exercise 03 result"
hashtag_count="$(temporal workflow show -w smoke-rust-social -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "HashtagActivities::fetch_hashtags")] | length')"
[ "$hashtag_count" -eq 1 ] || fail "exercise 03 must schedule HashtagActivities::fetch_hashtags"
stop_worker

echo "==> exercise 04"
run_worker publish-worker-solution
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-rust-publish --input '"pettok"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 8
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-rust-publish >/dev/null
[ "$(max_attempt_of smoke-rust-publish)" -gt 1 ] || fail "exercise 04 expected retries"
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-rust-dogbook --input '"dogbook"' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-rust-dogbook >/dev/null 2>&1 \
  && fail "dogbook should fail"
[ "$(max_attempt_of smoke-rust-dogbook)" -eq 1 ] || fail "dogbook should fail once"
temporal workflow execute --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-rust-publish-ok --input '"meowta"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-rust-publish-ok | grep -q "meowta-summer-splash" || fail "exercise 04 happy path"
stop_worker

echo "==> exercise 05"
run_worker approval-worker-solution
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-rust-approval --input '"summer-splash"' --input '60' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow signal -w smoke-rust-approval --name approve \
  --input '"Whiskers LeBlanc"' >/dev/null
temporal workflow result -w smoke-rust-approval >/dev/null
result_of smoke-rust-approval |
  jq -e '.status == "APPROVED" and .approved_by == "Whiskers LeBlanc"' >/dev/null \
  || fail "exercise 05 approved branch"
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-rust-expiry --input '"summer-splash"' --input '3' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-rust-expiry >/dev/null
result_of smoke-rust-expiry | jq -e '.status == "EXPIRED"' >/dev/null \
  || fail "exercise 05 expiry branch"
timer_count="$(temporal workflow show -w smoke-rust-expiry -o json |
  jq '[.events[] | select(.timerFiredEventAttributes != null)] | length')"
[ "$timer_count" -ge 1 ] || fail "exercise 05 expected durable timer"
stop_worker

echo "==> exercise 06"
run_worker campaign-worker-solution
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type CampaignWorkflow --task-queue campaign-tasks \
  -w smoke-rust-campaign --input '"summer-splash"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 6
stop_worker
status="$(temporal workflow describe -w smoke-rust-campaign -o json |
  jq -r '.workflowExecutionInfo.status')"
[ "$status" = "WORKFLOW_EXECUTION_STATUS_RUNNING" ] || fail "campaign did not survive kill"
run_worker campaign-worker-solution
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-rust-campaign >/dev/null
result_of smoke-rust-campaign |
  jq -e '.status == "LIVE" and .channels_live == 3 and all(.placements[]; . != null)' >/dev/null \
  || fail "exercise 06 report"
[ "$(max_attempt_of smoke-rust-campaign)" -gt 1 ] || fail "exercise 06 expected retries"
reserve_count="$(temporal workflow show -w smoke-rust-campaign -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "CampaignActivities::reserve_budget")] | length')"
[ "$reserve_count" -eq 1 ] || fail "CampaignActivities::reserve_budget should be scheduled once"
stop_worker

echo "==> exercise 07"
temporal workflow show -w smoke-rust-campaign -o json \
  > exercises/07-bonus-observability/history.json
practice_backup="$(mktemp -d)"
cp exercises/06-capstone/practice/*.rs "$practice_backup/"
cp exercises/06-capstone/solution/*.rs exercises/06-capstone/practice/
replay_ok=0
cargo run -q --bin replay -- smoke-rust-campaign >/tmp/rust-replay.log 2>&1 || true
grep -q "Replay OK" /tmp/rust-replay.log && replay_ok=1
cp "$practice_backup"/*.rs exercises/06-capstone/practice/
rm -f exercises/07-bonus-observability/history.json
[ "$replay_ok" -eq 1 ] || { cat /tmp/rust-replay.log >&2; fail "exercise 07 replay"; }

echo "==> exercise 08"
env -u TEMPORAL_ADDRESS -u TEMPORAL_NAMESPACE -u TEMPORAL_API_KEY \
  cargo run -q --bin cloud-worker >/tmp/rust-cloud.log 2>&1 \
  && fail "exercise 08 should reject missing credentials"
grep -q "TEMPORAL_ADDRESS" /tmp/rust-cloud.log || fail "exercise 08 error should name the missing variables"

echo "RUST SMOKE TEST PASSED"
