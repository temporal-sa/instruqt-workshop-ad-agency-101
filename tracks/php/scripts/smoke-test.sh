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
  local log="/tmp/php-worker-$exercise.log"
  rr serve -o server.command="php exercises/$exercise/solution/worker.php" \
    >"$log" 2>&1 &
  WORKER_PID=$!
  for _ in $(seq 1 40); do
    grep -q "RoadRunner server started" "$log" && break
    kill -0 "$WORKER_PID" 2>/dev/null || break
    sleep 0.5
  done
  grep -q "RoadRunner server started" "$log" \
    || fail "worker $exercise failed (see $log)"
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
php scripts/check.php

echo "==> services"
if ! temporal operator cluster health >/dev/null 2>&1; then
  smoke_db="$(mktemp -d)/temporal.db"
  temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --headless \
    --db-filename "$smoke_db" >/tmp/php-temporal.log 2>&1 &
  STARTED_SERVER=$!
  for _ in $(seq 1 30); do
    temporal operator cluster health >/dev/null 2>&1 && break
    sleep 1
  done
fi
temporal operator cluster health >/dev/null || fail "dev server did not start"

if ! curl -sf localhost:9999/health >/dev/null 2>&1; then
  .adnet-venv/bin/python services/adnet.py >/tmp/php-adnet.log 2>&1 &
  STARTED_ADNET=$!
  sleep 2
fi
curl -sf localhost:9999/health >/dev/null || fail "AdNet did not start"

echo "==> exercise 01"
curl -sf -X POST localhost:9999/chaos/on >/dev/null
if php exercises/01-meet-the-app/practice/app.php >/dev/null 2>&1; then
  fail "fragile app should fail while chaos is on"
fi

echo "==> exercise 02"
run_worker 02-first-workflow
temporal workflow execute --type TaglineWorkflow --task-queue tagline-tasks \
  -w smoke-php-tagline --input '"CatNip Cola"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-php-tagline | grep -q "CatNip Cola: Taste the Meow!" || fail "exercise 02 result"
stop_worker

echo "==> exercise 03"
run_worker 03-activities
temporal workflow execute --type SocialPostWorkflow --task-queue social-tasks \
  -w smoke-php-social --input '"catstagram"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-php-social | grep -q "#CatsOfCatstagram" || fail "exercise 03 result"
hashtag_count="$(temporal workflow show -w smoke-php-social -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "Hashtag.fetchHashtags")] | length')"
[ "$hashtag_count" -eq 1 ] || fail "exercise 03 must schedule Hashtag.fetchHashtags"
stop_worker

echo "==> exercise 04"
run_worker 04-retries-and-errors
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-php-publish --input '"pettok"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 8
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-php-publish >/dev/null
[ "$(max_attempt_of smoke-php-publish)" -gt 1 ] || fail "exercise 04 expected retries"
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-php-dogbook --input '"dogbook"' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-php-dogbook >/dev/null 2>&1 \
  && fail "dogbook should fail"
[ "$(max_attempt_of smoke-php-dogbook)" -eq 1 ] || fail "dogbook should fail once"
temporal workflow execute --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-php-publish-ok --input '"meowta"' \
  --id-conflict-policy TerminateExisting >/dev/null || fail "meowta should publish"
stop_worker

echo "==> exercise 05"
run_worker 05-human-in-the-loop
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-php-approval --input '"summer-splash"' --input '60' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow signal -w smoke-php-approval --name approve \
  --input '"Whiskers LeBlanc"' >/dev/null
temporal workflow result -w smoke-php-approval >/dev/null
result_of smoke-php-approval | jq -e '.status == "APPROVED" and .approved_by == "Whiskers LeBlanc"' >/dev/null \
  || fail "exercise 05 approved branch"
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-php-expiry --input '"summer-splash"' --input '3' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-php-expiry >/dev/null
result_of smoke-php-expiry | jq -e '.status == "EXPIRED" and .approved_by == null' >/dev/null \
  || fail "exercise 05 expiry branch"
timer_count="$(temporal workflow show -w smoke-php-expiry -o json |
  jq '[.events[] | select(.timerFiredEventAttributes != null)] | length')"
[ "$timer_count" -ge 1 ] || fail "exercise 05 expected durable timer"
stop_worker

echo "==> exercise 06"
run_worker 06-capstone
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type CampaignWorkflow --task-queue campaign-tasks \
  -w smoke-php-campaign --input '"summer-splash"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 6
stop_worker
status="$(temporal workflow describe -w smoke-php-campaign -o json |
  jq -r '.workflowExecutionInfo.status')"
[ "$status" = "WORKFLOW_EXECUTION_STATUS_RUNNING" ] || fail "campaign did not survive kill"
run_worker 06-capstone
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-php-campaign >/dev/null
result_of smoke-php-campaign | jq -e '.status == "LIVE" and .channels_live == 3 and all(.placements[]; . != null)' >/dev/null \
  || fail "exercise 06 report"
[ "$(max_attempt_of smoke-php-campaign)" -gt 1 ] || fail "exercise 06 expected retries"
reserve_count="$(temporal workflow show -w smoke-php-campaign -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "Campaign.reserveBudget")] | length')"
[ "$reserve_count" -eq 1 ] || fail "Campaign.reserveBudget should be scheduled once"
stop_worker

echo "==> exercise 07"
temporal workflow show -w smoke-php-campaign -o json \
  > exercises/07-bonus-observability/history.json
practice_backup="$(mktemp -d)"
cp exercises/06-capstone/practice/*.php "$practice_backup/"
cp exercises/06-capstone/solution/*.php exercises/06-capstone/practice/
replay_ok=0
php exercises/07-bonus-observability/replay.php |
  grep -q "Replay OK" && replay_ok=1
# Reordering two Activities must break replay.
perl -0pi -e 's/(.*validateCreative\(\$campaign\);\n)(.*reserveBudget\(\$campaign\);\n)/$2$1/' \
  exercises/06-capstone/practice/CampaignWorkflow.php
replay_broken=0
php exercises/07-bonus-observability/replay.php >/dev/null 2>&1 || replay_broken=1
cp "$practice_backup"/*.php exercises/06-capstone/practice/
rm -f exercises/07-bonus-observability/history.json
[ "$replay_ok" -eq 1 ] || fail "exercise 07 replay"
[ "$replay_broken" -eq 1 ] || fail "exercise 07 replay should reject reordered Activities"

echo "==> exercise 08"
cloud_exit=0
env -u TEMPORAL_ADDRESS -u TEMPORAL_NAMESPACE -u TEMPORAL_API_KEY \
  timeout 60 rr serve -c exercises/08-to-the-cloud/rr.yaml >/tmp/php-cloud-worker.log 2>&1 \
  || cloud_exit=$?
{ [ "$cloud_exit" -ne 0 ] && [ "$cloud_exit" -ne 124 ]; } \
  || fail "exercise 08 should reject missing credentials (exit $cloud_exit)"
grep -q "Set TEMPORAL_ADDRESS, TEMPORAL_NAMESPACE, TEMPORAL_API_KEY first" /tmp/php-cloud-worker.log \
  || fail "exercise 08 should name the missing credentials"

echo "PHP SMOKE TEST PASSED"
