#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

export TEMPORAL_ADDRESS="${TEMPORAL_ADDRESS:-127.0.0.1:7233}"
export DOTNET_CLI_TELEMETRY_OPTOUT=1 DOTNET_NOLOGO=1
STARTED_SERVER=""
STARTED_ADNET=""
WORKER_PROJECT=""

stop_worker() {
  [ -z "$WORKER_PROJECT" ] || pkill -f "$WORKER_PROJECT" 2>/dev/null || true
  for _ in $(seq 1 20); do
    [ -z "$WORKER_PROJECT" ] || pgrep -f "$WORKER_PROJECT" >/dev/null || break
    sleep 0.5
  done
  WORKER_PROJECT=""
}

cleanup() {
  stop_worker
  [ -z "$STARTED_SERVER" ] || kill "$STARTED_SERVER" 2>/dev/null || true
  [ -z "$STARTED_ADNET" ] || kill "$STARTED_ADNET" 2>/dev/null || true
}
trap cleanup EXIT

fail() { echo "SMOKE FAIL: $1" >&2; exit 1; }

# run_worker <exercise> <ProjectName>: start a solution Worker and wait for it
# to report that it is polling.
run_worker() {
  local exercise="$1"
  local project="$2"
  local log="/tmp/dotnet-worker-$exercise.log"
  dotnet run --project "exercises/$exercise/solution/$project.csproj" >"$log" 2>&1 &
  WORKER_PROJECT="$project"
  for _ in $(seq 1 120); do
    grep -q "Worker started" "$log" && return 0
    pgrep -f "$project" >/dev/null || break
    sleep 1
  done
  fail "worker $exercise failed (see $log)"
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
dotnet build CatNipCola.Workshop.slnx -nologo -v quiet

echo "==> services"
if ! temporal operator cluster health >/dev/null 2>&1; then
  smoke_db="$(mktemp -d)/temporal.db"
  temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --headless \
    --db-filename "$smoke_db" >/tmp/dotnet-temporal.log 2>&1 &
  STARTED_SERVER=$!
  for _ in $(seq 1 30); do
    temporal operator cluster health >/dev/null 2>&1 && break
    sleep 1
  done
fi
temporal operator cluster health >/dev/null || fail "dev server did not start"

if ! curl -sf localhost:9999/health >/dev/null 2>&1; then
  .adnet-venv/bin/python services/adnet.py >/tmp/dotnet-adnet.log 2>&1 &
  STARTED_ADNET=$!
  sleep 2
fi
curl -sf localhost:9999/health >/dev/null || fail "AdNet did not start"

echo "==> exercise 01"
curl -sf -X POST localhost:9999/chaos/on >/dev/null
if dotnet run --project exercises/01-meet-the-app/practice/CampaignApp.csproj >/dev/null 2>&1; then
  fail "fragile app should fail while chaos is on"
fi

echo "==> exercise 02"
run_worker 02-first-workflow TaglineWorker
temporal workflow execute --type TaglineWorkflow --task-queue tagline-tasks \
  -w smoke-dotnet-tagline --input '"CatNip Cola"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-dotnet-tagline | grep -q "CatNip Cola: Taste the Meow!" || fail "exercise 02 result"
stop_worker

echo "==> exercise 03"
run_worker 03-activities SocialPostWorker
temporal workflow execute --type SocialPostWorkflow --task-queue social-tasks \
  -w smoke-dotnet-social --input '"catstagram"' \
  --id-conflict-policy TerminateExisting >/dev/null
result_of smoke-dotnet-social | grep -q "#CatsOfCatstagram" || fail "exercise 03 result"
hashtag_count="$(temporal workflow show -w smoke-dotnet-social -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "FetchHashtags")] | length')"
[ "$hashtag_count" -eq 1 ] || fail "exercise 03 must schedule FetchHashtags"
stop_worker

echo "==> exercise 04"
run_worker 04-retries-and-errors PublishWorker
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-dotnet-publish --input '"pettok"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 8
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-dotnet-publish >/dev/null
[ "$(max_attempt_of smoke-dotnet-publish)" -gt 1 ] || fail "exercise 04 expected retries"
temporal workflow start --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-dotnet-dogbook --input '"dogbook"' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-dotnet-dogbook >/dev/null 2>&1 \
  && fail "dogbook should fail"
[ "$(max_attempt_of smoke-dotnet-dogbook)" -eq 1 ] || fail "dogbook should fail once"
temporal workflow execute --type PublishWorkflow --task-queue publish-tasks \
  -w smoke-dotnet-publish-ok --input '"meowta"' \
  --id-conflict-policy TerminateExisting >/dev/null || fail "exercise 04 happy path"
stop_worker

echo "==> exercise 05"
run_worker 05-human-in-the-loop ApprovalWorker
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-dotnet-approval --input '"summer-splash"' --input '60' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow signal -w smoke-dotnet-approval --name approve \
  --input '"Whiskers LeBlanc"' >/dev/null
temporal workflow result -w smoke-dotnet-approval >/dev/null
result_of smoke-dotnet-approval |
  jq -e '.status == "APPROVED" and .approved_by == "Whiskers LeBlanc"' >/dev/null \
  || fail "exercise 05 approved branch"
temporal workflow start --type CampaignApprovalWorkflow --task-queue approval-tasks \
  -w smoke-dotnet-expiry --input '"summer-splash"' --input '3' \
  --id-conflict-policy TerminateExisting >/dev/null
temporal workflow result -w smoke-dotnet-expiry >/dev/null
result_of smoke-dotnet-expiry | jq -e '.status == "EXPIRED" and .approved_by == null' >/dev/null \
  || fail "exercise 05 expiry branch"
timer_count="$(temporal workflow show -w smoke-dotnet-expiry -o json |
  jq '[.events[] | select(.timerFiredEventAttributes != null)] | length')"
[ "$timer_count" -ge 1 ] || fail "exercise 05 expected durable timer"
stop_worker

echo "==> exercise 06"
run_worker 06-capstone CampaignWorker
curl -sf -X POST localhost:9999/chaos/on >/dev/null
temporal workflow start --type CampaignWorkflow --task-queue campaign-tasks \
  -w smoke-dotnet-campaign --input '"summer-splash"' \
  --id-conflict-policy TerminateExisting >/dev/null
sleep 6
stop_worker
status="$(temporal workflow describe -w smoke-dotnet-campaign -o json |
  jq -r '.workflowExecutionInfo.status')"
[ "$status" = "WORKFLOW_EXECUTION_STATUS_RUNNING" ] || fail "campaign did not survive kill"
run_worker 06-capstone CampaignWorker
curl -sf -X POST localhost:9999/chaos/off >/dev/null
temporal workflow result -w smoke-dotnet-campaign >/dev/null
result_of smoke-dotnet-campaign |
  jq -e '.status == "LIVE" and .channels_live == 3 and all(.placements[]; . != null)' >/dev/null \
  || fail "exercise 06 report"
[ "$(max_attempt_of smoke-dotnet-campaign)" -gt 1 ] || fail "exercise 06 expected retries"
reserve_count="$(temporal workflow show -w smoke-dotnet-campaign -o json |
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "ReserveBudget")] | length')"
[ "$reserve_count" -eq 1 ] || fail "ReserveBudget should be scheduled once"
stop_worker

echo "==> exercise 07"
temporal workflow show -w smoke-dotnet-campaign -o json \
  > exercises/07-bonus-observability/history.json
practice_backup="$(mktemp -d)"
cp exercises/06-capstone/practice/*.cs "$practice_backup/"
cp exercises/06-capstone/solution/*.cs exercises/06-capstone/practice/
replay_ok=0
dotnet run --project exercises/07-bonus-observability/Replay.csproj |
  grep -q "Replay OK" && replay_ok=1
cp "$practice_backup"/*.cs exercises/06-capstone/practice/
rm -f exercises/07-bonus-observability/history.json
[ "$replay_ok" -eq 1 ] || fail "exercise 07 replay"

echo "==> exercise 08"
env -u TEMPORAL_ADDRESS -u TEMPORAL_NAMESPACE -u TEMPORAL_API_KEY \
  dotnet run --project exercises/08-to-the-cloud/CloudWorker.csproj >/dev/null 2>&1 \
  && fail "exercise 08 should reject missing credentials"

echo "DOTNET SMOKE TEST PASSED"
