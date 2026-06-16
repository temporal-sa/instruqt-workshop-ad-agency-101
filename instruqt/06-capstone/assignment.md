---
slug: capstone
id: fxs3yqysg3dx
type: challenge
title: '6. Capstone: make it durable'
teaser: The script from challenge 1, reborn. Kill the worker. Launch anyway.
notes:
- type: text
  contents: |-
    # The mission
    Take the exact script that died in challenge 1 and rebuild it as a
    durable Temporal application. Then launch through a real outage, **kill
    your own worker mid-flight**, and watch the campaign finish anyway.
- type: text
  contents: |-
    # It's a refactor, not a rewrite
    | app.py (challenge 1) | durable version (now) |
    |---|---|
    | plain function | function + `@activity.defn` |
    | `validate_creative(campaign)` | `await workflow.execute_activity(validate_creative, campaign, ...)` |
    | `launch_campaign()` | `CampaignWorkflow` class |
    | state in local variables | state in the event history |
    | crash = start over (double-spend!) | crash = resume where it left off |
tabs:
- id: pzqvdtzyu9he
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: jjyaspoa5kyr
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: byp58jtctszp
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: lhy8mxujblxl
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: it05tumri5y1
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: 2buuuf7xpzjg
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: sczkl3jubyn1
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: intermediate
timelimit: 1500
enhanced_loading: null
---

Everything you've learned, pointed back at the original problem.

# Step 1: Read the starting point

In the [button label="Editor"](tab-0) tab, open `06-capstone/practice/`:

- `activities.py` — the four functions from `app.py`, undecorated
- `workflows.py` — `CampaignWorkflow`, with the original orchestration
  shown in a comment
- `worker.py` — complete except for registrations

# Step 2: Decorate the activities

Add `@activity.defn` to all four functions in `06-capstone/practice/activities.py`.

# Step 3: Rebuild the orchestration durably

In `06-capstone/practice/workflows.py`, rebuild `launch_campaign`'s logic with
`execute_activity` calls (the TODO has the recipe). From challenges 3 and 4:

- every call needs a `start_to_close_timeout`
- `publish_to_channel` needs a `RetryPolicy` — include
  `non_retryable_error_types=["ChannelPolicyError"]`, the policy-side twin
  of `ApplicationError(non_retryable=True)`
- multi-argument activities use `args=[campaign, channel]`

# Step 4: Business errors

Give `publish_to_channel` the 4xx → `ApplicationError(...,
type="ChannelPolicyError", non_retryable=True)` treatment from challenge 4.
Same cautions as there: the comparison reads `400 <= resp.status_code < 500`
(not `>=`!) and the raise goes **inside** it — if your launch fails with a
success body inside a "rejected" error, your check is matching successes.

# Step 5: Wire the worker

Register the workflow and all four activities in `06-capstone/practice/worker.py`.

# Step 6: Launch through the chaos

Chaos is on (we made sure) — this launch is supposed to hurt. In the
[button label="Worker"](tab-3) tab (Ctrl-C any old worker):

```bash,run
uv run exercises/06-capstone/practice/worker.py
```

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type CampaignWorkflow \
  --task-queue campaign-tasks \
  --workflow-id campaign-summer-splash \
  --input '"summer-splash"'
```

In the [button label="Temporal UI"](tab-5): creative validated ✓, budget
reserved ✓, Meowta live ✓, Catstagram live ✓... and PetTok retrying under
**Pending Activities**. *Exactly* where challenge 1's script died.

# Step 7: Kill the worker

While PetTok is still retrying, go to the [button label="Worker"](tab-3) tab and **Ctrl-C it**.
The process executing your campaign is gone — in challenge 1, this was the
catastrophe.

Look at the [button label="Temporal UI"](tab-5): `campaign-summer-splash` is still **Running**. Every
completed step is in the event history — the budget reservation, the two
live channels. Recorded. Safe. Server-side.

Restart the worker in the [button label="Worker"](tab-3) tab:

```bash,run
uv run exercises/06-capstone/practice/worker.py
```

It picks up exactly where things left off — `reserve_budget` does **not**
run again. End the outage and collect the result ([button label="CLI"](tab-4) tab):

```bash,run
curl -X POST localhost:9999/chaos/off
```

```bash,run
temporal workflow result -w campaign-summer-splash
```

One launch. One budget reservation. Three channels live. A process kill and
a channel outage in the middle — and none of it mattered. Hit **Check**.

# Stretch (if you have time)

Publish to all three channels **in parallel**: build the three
`execute_activity(...)` coroutines without awaiting them, then
`placements = list(await asyncio.gather(*tasks))` (add `import asyncio`).
If you wrap the call in a helper `async def` instead, remember to
**`return`** the awaited result — `placements` full of `null` is the tell.
Run it as `campaign-parallel` and compare the timelines in the [button label="Temporal UI"](tab-5).

> [!NOTE]
> Stuck? Compare with `06-capstone/solution/` in the [button label="Editor"](tab-0) tab.
