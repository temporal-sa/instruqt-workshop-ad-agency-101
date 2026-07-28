---
slug: retries-and-errors
id: nyxkkiweftky
type: challenge
title: 4. Failures, retries, and error handling
teaser: Publish into a burning API. Watch Temporal outlast the fire.
notes:
- type: text
  contents: |-
    # Concepts for this challenge
    **Retries are the default.** When an activity raises, Temporal retries
    it — automatically, with exponential backoff, surviving worker restarts.
    The failure handling lives in the platform, not in a try/except pyramid.

    While it's retrying, the Web UI's **Pending Activities** shows the
    attempt count, next retry time, and last failure. Your live window into
    an outage.
- type: text
  contents: |-
    # Transient vs. business failures
    - A **503** means *try again later* → let it retry.
    - A **4xx** means *the answer is no* → retrying is noise at best.

    ```python
    raise ApplicationError("...", type="ChannelPolicyError", non_retryable=True)
    ```

    The error `type` travels to the workflow and the UI, so callers know
    *what kind* of "no" they got.

    **Know the defaults:** activities' exceptions — `ApplicationError`
    included — are ALL retryable; `non_retryable=True` is the explicit
    opt-out. (In *workflow* code the rules flip: `ApplicationError` fails
    the workflow immediately; ordinary exceptions retry the workflow task.)

    **Two places to say "don't retry":** raise-site —
    `ApplicationError(..., non_retryable=True)`, the activity knows best —
    or caller-side, in the policy:
    `RetryPolicy(non_retryable_error_types=["ChannelPolicyError"])`, the
    workflow decides. Both match on the error's `type`. The capstone uses
    both.
tabs:
- id: tepguwcyffuu
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: raif1mssd7gr
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: sfwyxovim9ab
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: qekndnqs66xs
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: x2zmheyxuvtk
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: ies7ailojq82
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: aweg8hmvqaiy
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: intermediate
timelimit: 1200
enhanced_loading: null
---

PetTok's API is down (chaos mode is back on — we made sure). Publish
anyway, and let Temporal deal with it.

# Step 1: Publish into the fire

In the [button label="Worker"](tab-3) tab (Ctrl-C any old worker):

```bash,run
uv run exercises/04-retries-and-errors/practice/worker.py
```

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-1 \
  --input '"pettok"'
```

Open `publish-1` in the [button label="Temporal UI"](tab-5). Under
**Pending Activities**, watch the attempt counter climb and read the last
failure: `503 ... /publish/pettok`. Glance at the [button label="Worker"](tab-3) tab: every
attempt logs a traceback, and nothing crashes. The workflow is calmly
outlasting the outage.

# Step 2: Fix the outage

You're also on-call for AdNet today. Restore PetTok ([button label="CLI"](tab-4) tab):

```bash,run
curl -X POST localhost:9999/chaos/off
```

Watch the [button label="Temporal UI"](tab-5): the next retry succeeds and `publish-1` completes.

```bash,run
temporal workflow result -w publish-1
```

Nobody re-ran anything. The retry policy did the work.

# Step 3: Tune the policy

In the [button label="Editor"](tab-0) tab, `04-retries-and-errors/practice/workflows.py`: follow the TODO and add the
custom `RetryPolicy`.

> [!IMPORTANT]
> **Restart your worker.** Workers run the code they loaded at startup —
> every edit needs a restart. Make it a reflex now.

# Step 4: When retrying is wrong

CatNip Cola is **banned** on Dogbook. AdNet answers 403, every time,
forever. See what default behavior does with that, in the
[button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-2 \
  --input '"dogbook"'
```

In the [button label="Temporal UI"](tab-5): retrying. Forever. Pointlessly. Put it out of its misery — your
first workflow termination:

```bash,run
temporal workflow terminate -w publish-2 --reason "retrying a permanent failure"
```

Now fix the activity: in `04-retries-and-errors/practice/activities.py`, follow the TODO — detect
4xx responses and raise `ApplicationError(..., type="ChannelPolicyError",
non_retryable=True)`. **Restart your worker** in the
[button label="Worker"](tab-3) tab, then try Dogbook again in the
[button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-3 \
  --input '"dogbook"'
```

`publish-3` fails in under a second — one attempt, a typed
`ChannelPolicyError`, no retry storm. Failing *fast* with a *typed* error
is as much a feature as retrying.

One more publish — **prove you didn't break success**:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-ok \
  --input '"meowta"'
```

```bash,run
temporal workflow result -w publish-ok
```

It must complete. If it FAILS with a "rejected" message that *contains a
placement_id* — a success body wrapped in an error — your error handling is
matching successes: either the comparison is flipped (`400 >=` is true for
a 200 and false for a 403 — chained comparisons!) or the raise drifted
outside the `if`. Make it `400 <= resp.status_code < 500` with the raise
inside, restart the worker, re-run.

When `publish-1` has completed (with battle scars), `publish-3` has failed
fast, and `publish-ok` has succeeded, hit **Check**.

# Stretch 1: bounded retries (if you have time)

Turn chaos back on (`curl -X POST localhost:9999/chaos/on`), set
`maximum_attempts=3` in your retry policy, restart the worker, and publish
to pettok as `publish-4`. Watch it exhaust three attempts and fail with an
`ActivityError` — read the failure chain in the [button label="Temporal UI"](tab-5). Remove
`maximum_attempts` and turn chaos off afterwards.

# Stretch 2: hot-fix a bug mid-flight (if you have time)

Outages aren't the only failures retries absorb — **your own bugs are
survivable too**. With chaos off and `maximum_attempts` removed, ship a bad
deploy on purpose: in `04-retries-and-errors/practice/activities.py`,
change `resp.json()["placement_id"]` to `resp.json()["placement_idd"]`.
Restart the worker in the [button label="Worker"](tab-3) tab, then
publish to a perfectly healthy channel from the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-5 \
  --input '"meowta"'
```

The workflow gets stuck: in the [button label="Temporal UI"](tab-5),
**Pending Activities** shows attempt after attempt failing with
`KeyError: 'placement_idd'`. AdNet is healthy — the failure is *your code*.
In production, this is a bad deploy going out with workflows in flight.

Now ship the fix: correct the typo back to `placement_id`, restart the
worker, and **don't touch the workflow**. Within seconds the next retry
runs the fixed code and `publish-5` completes:

```bash,run
temporal workflow result -w publish-5
```

In-flight workflows survive your bad deploys: fix the code, restart the
workers, and every stuck workflow unsticks itself on its next attempt — no
resets, no manual replays, no incident runbook.

> [!NOTE]
> Stuck? Compare with `04-retries-and-errors/solution/` in the [button label="Editor"](tab-0) tab.
