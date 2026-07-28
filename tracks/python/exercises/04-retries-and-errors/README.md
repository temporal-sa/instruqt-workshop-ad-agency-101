# Exercise 4: Failures, retries, and error handling

**Goal:** publish CatNip Cola's post while AdNet burns. Watch Temporal retry
through a real outage, tune the retry policy, and teach it the difference
between "try again" and "give up."

## Concepts

**Retries are the default.** When an activity raises, Temporal retries it —
automatically, with exponential backoff, forever (by default), surviving
worker restarts. No try/except pyramid in your code; the failure handling
lives in the platform.

**You can watch it happen.** While an activity is retrying, the Web UI shows
it under **Pending Activities**: the attempt count, the next retry time, and
the last failure message. This is your live window into an outage.

**Custom retry policies.** The defaults (1s initial, 2.0 backoff coefficient,
100s max interval, unlimited attempts) are right most of the time — change
them only when you have a domain reason to. The knobs:

```python
retry_policy=RetryPolicy(
    initial_interval=timedelta(seconds=1),
    backoff_coefficient=2.0,
    maximum_interval=timedelta(seconds=10),
    # maximum_attempts=5,   # unlimited if unset
)
```

**Transient vs. business failures.** A 503 means *try again later* — retry.
A 4xx means *the answer is no* — retrying is at best noise and at worst a
bug. Raise a non-retryable error for those:

```python
raise ApplicationError("...", type="ChannelPolicyError", non_retryable=True)
```

The error `type` travels to the workflow and the UI, so callers can react to
*what kind* of "no" it was.

**Two places to declare "don't retry."** `non_retryable=True` is the
*raise-site* form: the activity itself knows this failure is permanent, and
the decision ships inside the error to every caller. The same decision can
also live *caller-side*, in the retry policy:

```python
retry_policy=RetryPolicy(
    initial_interval=timedelta(seconds=1),
    backoff_coefficient=2.0,
    maximum_interval=timedelta(seconds=10),
    non_retryable_error_types=["ChannelPolicyError"],
)
```

`non_retryable_error_types` matches on the error's `type` string — which is
the real reason typed errors matter. Use the raise-site form when the
activity knows best; use the policy form when the *workflow* decides — for
example when you don't own the activity's code, or when different workflows
want different patience for the same activity. (They compose fine: the
capstone uses both, deliberately.)

**Know the defaults.** Temporal treats **every** exception an activity
raises as retryable — including `ApplicationError` itself. What
`ApplicationError` buys you is structure: a `type` that the workflow, the
UI, and `non_retryable_error_types` policies can match on, plus the
`non_retryable=True` switch — the explicit opt-out from retries. And one
asymmetry worth knowing: in *workflow* code the rules flip. Raising
`ApplicationError` there fails the workflow immediately, while an ordinary
exception in workflow code fails the *workflow task* — which Temporal
retries indefinitely on the assumption it's a transient bug you'll hot-fix
(exactly the move Stretch 2 practices with an activity).

## Part A: Publish into the fire

AdNet's chaos mode is on, which means PetTok's API is down. Start your worker
and throw a publish at it anyway:

```bash
uv run exercises/04-retries-and-errors/practice/worker.py
```

```bash
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-1 \
  --input '"pettok"'
```

Open `publish-1` in the Web UI. Under **Pending Activities** watch the
attempt counter climb and read the last failure: `503 ... /publish/pettok`.
Notice the worker terminal: each attempt logs a traceback — and nothing
crashes. The workflow is calmly outlasting the outage.

## Part B: Fix the outage

You're also on-call for AdNet today. Restore PetTok:

```bash
curl -X POST localhost:9999/chaos/off
```

Watch `publish-1` in the UI: the next retry succeeds and the workflow
completes. Get the result:

```bash
temporal workflow result -w publish-1
```

Nobody re-ran anything. The retry policy did the work.

## Part C: Tune the policy

In `practice/workflows.py`, follow the TODO and add the custom `RetryPolicy`.

> **Restart your worker.** Workers run the code they loaded at startup.
> Every code edit needs a worker restart — make it a reflex now.

## Part D: When retrying is wrong

CatNip Cola is banned on Dogbook. AdNet will answer 403 every single time.
See what the default behavior does with that:

```bash
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-2 \
  --input '"dogbook"'
```

In the UI: retrying. Forever. Pointlessly. Put it out of its misery — your
first workflow termination:

```bash
temporal workflow terminate -w publish-2 --reason "retrying a permanent failure"
```

Now fix the activity: in `practice/activities.py`, follow the TODO — detect
4xx responses and raise `ApplicationError(..., type="ChannelPolicyError",
non_retryable=True)`. Restart your worker, then try Dogbook again:

```bash
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-3 \
  --input '"dogbook"'
```

`publish-3` fails in under a second — one attempt, a clear
`ChannelPolicyError`, no retry storm. Failing *fast* with a *typed* error is
just as much a feature as retrying.

One more publish before moving on — **prove you didn't break success**:

```bash
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-ok \
  --input '"meowta"'
temporal workflow result -w publish-ok     # must complete: "meowta-summer-splash"
```

Error handling that matches *successes* is a classic slip — a flipped
comparison (`400 >= resp.status_code`, which is true for a 200 and false
for a 403, thanks to Python's chained comparisons) or a raise that drifted
outside the `if` — and Temporal will faithfully fail-fast your perfectly
good publishes. The tell: `publish-ok` FAILS with a "rejected" message that
*contains a placement_id* — a success body wrapped in an error. If you see
that, re-check the condition reads `400 <= resp.status_code < 500` and the
raise sits inside it. Fix, restart the worker, re-run.

## Verify your work

```bash
# publish-1 completed AND took more than one attempt:
temporal workflow show -w publish-1 -o json | \
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'   # > 1

# publish-3 failed on exactly one attempt:
temporal workflow describe -w publish-3 -o json | jq -r '.workflowExecutionInfo.status'
# WORKFLOW_EXECUTION_STATUS_FAILED
temporal workflow show -w publish-3 -o json | \
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'   # == 1

# and the happy path still works:
temporal workflow describe -w publish-ok -o json | jq -r '.workflowExecutionInfo.status'
# WORKFLOW_EXECUTION_STATUS_COMPLETED
```

## Stretch 1: bounded retries (if you have time)

Turn chaos back on (`curl -X POST localhost:9999/chaos/on`), set
`maximum_attempts=3` in your retry policy, restart the worker, and publish to
pettok as `publish-4`. Watch it exhaust its three attempts and fail with an
`ActivityError` — then read the failure chain in the UI. Remove
`maximum_attempts` and turn chaos off when you're done.

## Stretch 2: hot-fix a bug mid-flight (if you have time)

Outages aren't the only failures retries absorb — **your own bugs are
survivable too**. Make sure chaos is off and `maximum_attempts` is removed,
then ship a bad deploy on purpose: in `practice/activities.py`, change
`resp.json()["placement_id"]` to `resp.json()["placement_idd"]`. Restart
the worker, then publish to a perfectly healthy channel:

```bash
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-5 \
  --input '"meowta"'
```

The workflow gets stuck. Pending Activities shows attempt after attempt
failing with `KeyError: 'placement_idd'` — AdNet is healthy; the failure is
*your code*. In production, this is the moment a bad deploy went out with
workflows in flight.

Now ship the fix: correct the typo back to `placement_id` and restart the
worker. **Don't touch the workflow.** Within seconds, the next retry runs
the fixed code and the workflow completes:

```bash
temporal workflow result -w publish-5
```

That's the operational superpower hiding inside retries: in-flight
workflows survive your bad deploys. Fix the code, restart the workers, and
every stuck workflow unsticks itself on its next attempt — no resets, no
manual replays, no incident runbook.

---

*Stuck or want to compare? See the `solution/` directory.*
