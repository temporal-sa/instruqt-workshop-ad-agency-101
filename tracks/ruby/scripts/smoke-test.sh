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

run_worker() {
  local exercise="$1"
  bundle exec ruby "exercises/$exercise/solution/worker.rb" \
    >"/tmp/ruby-worker-$exercise.log" 2>&1 &
  WORKER_PID=$!
  sleep 4
  kill -0 "$WORKER_PID" 2>/dev/null \
    || fail "worker $exercise failed (see /tmp/ruby-worker-$exercise.log)"
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
bash scripts/check.sh

echo "==> services"
if ! temporal operator cluster health >/dev/null 2>&1; then
  smoke_db="$(mktemp -d)/temporal.db"
  temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --headless \
    --db-filename "$smoke_db" >/tmp/ruby-temporal.log 2>&1 &
  STARTED_SERVER=$!
  for _ in $(seq 1 30); do
    temporal operator cluster health >/dev/null 2>&1 && break
    sleep 1
  done
fi
temporal operator cluster health >/dev/null || fail "dev server did not start"

if ! curl -sf localhost:9999/health >/dev/null 2>&1; then
  .adnet-venv/bin/python services/adnet.py >/tmp/ruby-adnet.log 2>&1 &
  STARTED_ADNET=$!
  sleep 2
fi
curl -sf localhost:9999/health >/dev/null || fail "AdNet did not start"

echo "==> exercise 01"
curl -sf -X POST localhost:9999/chaos/on >/dev/null
if bundle exec ruby exercises/01-meet-the-app/practice/app.rb >/dev/null 2>&1; then
  fail "fragile app should fail while chaos is on"
fi

echo "==> exercise 02"
run_worker 02-first-workflow
temporal workflow execute --type TaglineWorkflow --task-queue tagline-tasks \
  -w smoke-ruby-tagline --input '"CatNip Cola"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-ruby-tagline | grep -q "Taste the Meow" || fail "exercise 02 result"
stop_worker

echo "==> exercise 03"
run_worker 03-activities
temporal workflow execute --type SocialPostWorkflow --task-queue social-tasks \
  -w smoke-ruby-social --input '"catstagram"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-ruby-social | grep -q "#CatsOfCatstagram" || fail "exercise 03 result"
hashtag_count="$(temporal workflow show -w smoke-ruby-social -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "FetchHashtags")] | length')"
[ "$hashtag_count" -eq 1 ] || fail "exercise 03 must schedule FetchHashtags"
stop_worker

echo "==> exercise 04"
run_worker 04-retries-and-errors
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-ruby-publish --input '"pettok"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 8
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-ruby-publish >/dev/null
[ "$(max_attempt_of smoke-ruby-publish)" -gt 1 ] || fail "exercise 04 expected retries"
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-ruby-dogbook --input '"dogbook"' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-ruby-dogbook >/dev/null 2>&1 \
  && fail "dogbook should fail"
[ "$(max_attempt_of smoke-ruby-dogbook)" -eq 1 ] || fail "dogbook should fail once"
stop_worker

echo "==> exercise 05"
run_worker 05-human-in-the-loop
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-ruby-approval --input '"summer-splash"' --input '60' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow signal -w smoke-ruby-approval --name approve \
  --input '"Whiskers LeBlanc"' >/dev/null
temporal workflow result -w smoke-ruby-approval >/dev/null
result_of smoke-ruby-approval | jq -e '.status == "APPROVED"' >/dev/null \
  || fail "exercise 05 approved branch"
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-ruby-expiry --input '"summer-splash"' --input '3' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-ruby-expiry >/dev/null
result_of smoke-ruby-expiry | jq -e '.status == "EXPIRED"' >/dev/null \
  || fail "exercise 05 expiry branch"
timer_count="$(temporal workflow show -w smoke-ruby-expiry -o json |
  jq '[.events[] | select(.timerFiredEventAttributes != null)] | length')"
[ "$timer_count" -ge 1 ] || fail "exercise 05 expected durable timer"
stop_worker

echo "==> exercise 06"
run_worker 06-capstone
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type CampaignWorkflow --task-queue campaign-tasks \
  -w smoke-ruby-campaign --input '"summer-splash"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 6
stop_worker
status="$(temporal workflow describe -w smoke-ruby-campaign -o json |
  jq -r '.workflowExecutionInfo.status')"
[ "$status" = "WORKFLOW_EXECUTION_STATUS_RUNNING" ] || fail "campaign did not survive kill"
run_worker 06-capstone
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-ruby-campaign >/dev/null
result_of smoke-ruby-campaign | jq -e '.status == "LIVE" and .channels_live == 3' >/dev/null \
  || fail "exercise 06 report"
[ "$(max_attempt_of smoke-ruby-campaign)" -gt 1 ] || fail "exercise 06 expected retries"
reserve_count="$(temporal workflow show -w smoke-ruby-campaign -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "ReserveBudget")] | length')"
[ "$reserve_count" -eq 1 ] || fail "ReserveBudget should be scheduled once"
stop_worker

echo "==> exercise 07"
temporal workflow show -w smoke-ruby-campaign -o json \
  > exercises/07-bonus-observability/history.json
practice_backup="$(mktemp -d)"
cp exercises/06-capstone/practice/*.rb "$practice_backup/"
cp exercises/06-capstone/solution/*.rb exercises/06-capstone/practice/
replay_ok=0
bundle exec ruby exercises/07-bonus-observability/replay.rb |
  grep -q "Replay OK" && replay_ok=1
cp "$practice_backup"/*.rb exercises/06-capstone/practice/
rm -f exercises/07-bonus-observability/history.json
[ "$replay_ok" -eq 1 ] || fail "exercise 07 replay"

echo "==> exercise 08"
env -u TEMPORAL_ADDRESS -u TEMPORAL_NAMESPACE -u TEMPORAL_API_KEY \
  bundle exec ruby exercises/08-to-the-cloud/worker.rb >/dev/null 2>&1 \
  && fail "exercise 08 should reject missing credentials"

echo "RUBY SMOKE TEST PASSED"
