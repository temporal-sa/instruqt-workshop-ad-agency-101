#!/usr/bin/env bash
# Smoke-test every exercise solution end-to-end against a real dev server.
# Usage: ./scripts/smoke-test.sh   (from anywhere; requires uv + temporal CLI)
#
# Reuses an already-running dev server on 7233 if healthy; otherwise starts a
# throwaway one. Workflow IDs are smoke-* so reruns and learner state don't
# collide. Exits non-zero on the first failed assertion.
set -euo pipefail
cd "$(dirname "$0")/.."

# Explicit IPv4: avoids flaky `localhost` resolution on some machines.
export TEMPORAL_ADDRESS="${TEMPORAL_ADDRESS:-127.0.0.1:7233}"

STARTED_SERVER=""
STARTED_ADNET=""
cleanup() {
  pkill -f "solution/worker.py" 2>/dev/null || true
  [ -n "$STARTED_SERVER" ] && kill "$STARTED_SERVER" 2>/dev/null || true
  [ -n "$STARTED_ADNET" ] && kill "$STARTED_ADNET" 2>/dev/null || true
}
trap cleanup EXIT

fail() { echo "SMOKE FAIL: $1" >&2; exit 1; }

run_worker() { # $1 = exercise dir
  uv run "exercises/$1/solution/worker.py" >"/tmp/smoke-worker-$1.log" 2>&1 &
  for i in $(seq 1 10); do
    sleep 1
    pgrep -f "$1/solution/worker.py" >/dev/null && return 0
  done
  fail "worker for $1 did not start (see /tmp/smoke-worker-$1.log)"
}

stop_workers() { pkill -f "solution/worker.py" 2>/dev/null || true; sleep 1; }

result_of() { # $1 = workflow id -> decoded result payload
  temporal workflow show -w "$1" -o json |
    jq -r '[.events[] | select(.workflowExecutionCompletedEventAttributes != null)][0].workflowExecutionCompletedEventAttributes.result.payloads[0].data' |
    base64 -d
}

max_attempt_of() { # $1 = workflow id
  temporal workflow show -w "$1" -o json |
    jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
}

echo "==> services"
if ! temporal operator cluster health >/dev/null 2>&1; then
  SMOKE_DB="$(mktemp -d)/temporal.db"
  temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --headless \
    --db-filename "$SMOKE_DB" >/tmp/smoke-temporal.log 2>&1 &
  STARTED_SERVER=$!
  for i in $(seq 1 30); do
    temporal operator cluster health >/dev/null 2>&1 && break
    sleep 1
  done
fi
temporal operator cluster health >/dev/null || fail "dev server did not come up"

if ! curl -sf localhost:9999/health >/dev/null 2>&1; then
  uv run services/adnet.py >/tmp/smoke-adnet.log 2>&1 &
  STARTED_ADNET=$!
  sleep 2
fi
curl -sf localhost:9999/health >/dev/null || fail "adnet did not come up"
curl -sf -X POST localhost:9999/chaos/on >/dev/null

echo "==> unit tests (AdNet)"
uv run pytest tests/ -q >/dev/null || fail "AdNet unit tests"

echo "==> exercise 01: fragile app crashes mid-launch"
if uv run exercises/01-meet-the-app/practice/app.py >/dev/null 2>&1; then
  fail "app.py should crash while chaos is on"
fi

echo "==> exercise 02: TaglineWorkflow"
run_worker 02-first-workflow
temporal workflow execute --type TaglineWorkflow --task-queue tagline-tasks \
  -w smoke-tagline --input '"CatNip Cola"' --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-tagline | grep -q "Taste the Meow" || fail "ex02 result"
stop_workers

echo "==> exercise 03: SocialPostWorkflow"
run_worker 03-activities
temporal workflow execute --type SocialPostWorkflow --task-queue social-tasks \
  -w smoke-social --input '"catstagram"' --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-social | grep -q "#CatsOfCatstagram" || fail "ex03 result"
stop_workers

echo "==> exercise 04: retries then recovery, and fail-fast on dogbook"
run_worker 04-retries-and-errors
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-publish --input '"pettok"' --id-conflict-policy TerminateExisting >/dev/null
sleep 8
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-publish >/dev/null
[ "$(max_attempt_of smoke-publish)" -gt 1 ] || fail "ex04 expected retries on pettok"
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-dogbook --input '"dogbook"' --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-dogbook >/dev/null 2>&1 && fail "dogbook should fail"
[ "$(max_attempt_of smoke-dogbook)" -eq 1 ] || fail "ex04 dogbook should fail on attempt 1"
stop_workers

echo "==> exercise 05: human in the loop (signal, durable timer, branching)"
run_worker 05-human-in-the-loop
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-approval-yes --input '"summer-splash"' --input '60' --id-conflict-policy TerminateExisting >/dev/null
sleep 1
temporal workflow signal -w smoke-approval-yes --name approve --input '"Whiskers LeBlanc"' >/dev/null
temporal workflow result -w smoke-approval-yes >/dev/null
result_of smoke-approval-yes | jq -e '.status == "APPROVED" and .approved_by == "Whiskers LeBlanc"' >/dev/null \
  || fail "ex05 approved branch"
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-approval-no --input '"summer-splash"' --input '5' --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-approval-no >/dev/null
result_of smoke-approval-no | jq -e '.status == "EXPIRED"' >/dev/null || fail "ex05 expiry branch"
timer_fired=$(temporal workflow show -w smoke-approval-no -o json |
  jq '[.events[] | select(.timerFiredEventAttributes != null)] | length')
[ "$timer_fired" -ge 1 ] || fail "ex05 expected a fired durable timer in history"
stop_workers

echo "==> exercise 06: capstone with worker kill mid-retry"
curl -sf -X POST localhost:9999/chaos/on >/dev/null
run_worker 06-capstone
temporal workflow start --type CampaignWorkflow --task-queue campaign-tasks \
  -w smoke-campaign --input '"summer-splash"' --id-conflict-policy TerminateExisting >/dev/null
sleep 6
pkill -f "06-capstone/solution/worker.py"   # the workshop's Ctrl-C moment
sleep 2
status=$(temporal workflow describe -w smoke-campaign -o json | jq -r '.workflowExecutionInfo.status')
[ "$status" = "WORKFLOW_EXECUTION_STATUS_RUNNING" ] || fail "ex06 should still be RUNNING after worker kill (got $status)"
run_worker 06-capstone
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-campaign >/dev/null
result_of smoke-campaign | jq -e '.status == "LIVE" and .channels_live == 3' >/dev/null \
  || fail "ex06 report"
[ "$(max_attempt_of smoke-campaign)" -gt 1 ] || fail "ex06 expected retries"
reserve_count=$(temporal workflow show -w smoke-campaign -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "reserve_budget")] | length')
[ "$reserve_count" -eq 1 ] || fail "ex06 reserve_budget should be scheduled exactly once (got $reserve_count)"
stop_workers

echo "==> exercise 07: replayer (against capstone solution code)"
temporal workflow show -w smoke-campaign -o json \
  > exercises/07-bonus-observability/history.json
PRACTICE_BACKUP="$(mktemp -d)"
cp exercises/06-capstone/practice/*.py "$PRACTICE_BACKUP/"
cp exercises/06-capstone/solution/*.py exercises/06-capstone/practice/
replay_ok=0
uv run exercises/07-bonus-observability/replay.py | grep -q "Replay OK" && replay_ok=1
cp "$PRACTICE_BACKUP"/*.py exercises/06-capstone/practice/
rm -f exercises/07-bonus-observability/history.json
[ "$replay_ok" -eq 1 ] || fail "ex07 replay"

echo "==> exercise 08: cloud worker (import + env guard only; needs real Cloud creds to run)"
( cd exercises/08-to-the-cloud && uv run python -c "import workflows, worker" ) \
  || fail "ex08 imports"
env -u TEMPORAL_NAMESPACE -u TEMPORAL_API_KEY \
  uv run exercises/08-to-the-cloud/worker.py >/dev/null 2>&1 \
  && fail "ex08 should refuse to start without TEMPORAL_* env vars"

echo "SMOKE TEST PASSED"
