# Exercise 6: Capstone — make it durable

**Goal:** take the exact script that died in exercise 1 and rebuild it as a
durable Temporal application. Then launch the campaign through a real outage,
kill the worker mid-flight, and watch the launch finish anyway.

This is a **refactoring** exercise. You're not writing a new app. The four
functions are the same; the orchestration logic is the same. What changes:

| app.py (exercise 1) | Durable version (now) |
|---|---|
| plain function | function + `@activity.defn` |
| `validate_creative(campaign)` | `await workflow.execute_activity(validate_creative, campaign, ...)` |
| `launch_campaign()` function | `CampaignWorkflow` class |
| state in local variables | state in the event history |
| crash = start over (and double-spend) | crash = resume where it left off |

## Part A: Read the starting point

Open `exercises/06-capstone/practice/`:

- `activities.py` — the four functions from `app.py`, undecorated
- `workflows.py` — `CampaignWorkflow` with the original orchestration shown
  in a comment
- `worker.py` — complete except for registrations

## Part B: Decorate the activities

Add `@activity.defn` to all four functions in `practice/activities.py`.

## Part C: Rebuild the orchestration durably

In `practice/workflows.py`, rebuild `launch_campaign`'s logic with
`execute_activity` calls (the TODO has the recipe). Remember from exercises
3 and 4:

- every call needs a `start_to_close_timeout`
- `publish_to_channel` needs a `RetryPolicy` — include
  `non_retryable_error_types=["ChannelPolicyError"]`, which is the
  policy-side twin of `ApplicationError(non_retryable=True)`
- multi-argument activities use `args=[campaign, channel]`

## Part D: Business errors

In `practice/activities.py`, give `publish_to_channel` the 4xx →
`ApplicationError(..., type="ChannelPolicyError", non_retryable=True)`
treatment from exercise 4. Same cautions as there: the comparison reads
`400 <= resp.status_code < 500` (not `>=`!) and the raise goes **inside**
it — if your launch fails with a success body inside a "rejected" error,
your check is matching successes.

## Part E: Wire the worker

Register the workflow and all four activities in `practice/worker.py`.

## Part F: Launch through the chaos

Make sure AdNet's chaos mode is **on** — we want this launch to hurt:

```bash
curl -X POST localhost:9999/chaos/on
```

Start your worker:

```bash
uv run exercises/06-capstone/practice/worker.py
```

Launch:

```bash
temporal workflow start \
  --type CampaignWorkflow \
  --task-queue campaign-tasks \
  --workflow-id campaign-summer-splash \
  --input '"summer-splash"'
```

In the Web UI, watch the run: creative validated ✓, budget reserved ✓,
Meowta live ✓, Catstagram live ✓... and PetTok retrying under **Pending
Activities**. Exactly where exercise 1's script died. This time, nothing is
dying.

## Part G: Kill the worker

While PetTok is still retrying, go to your worker terminal and **Ctrl-C it**.
The process that was executing your campaign is now gone — in exercise 1
this was the catastrophe.

Look at the Web UI: `campaign-summer-splash` is still **Running**. Every
completed step is in the event history. The budget reservation, the two live
channels — recorded, safe, server-side.

Restart the worker:

```bash
uv run exercises/06-capstone/practice/worker.py
```

It picks up the workflow exactly where it left off — **`reserve_budget` does
not run again** (check the history: one `reserve_budget`, scheduled exactly
once). PetTok is still retrying. End the outage:

```bash
curl -X POST localhost:9999/chaos/off
```

And collect marketing's good news:

```bash
temporal workflow result -w campaign-summer-splash
```

```json
{"campaign": "summer-splash", "status": "LIVE", "channels_live": 3, ...}
```

One launch. One budget reservation. Three channels. A process kill and a
channel outage in the middle — and none of it mattered.

## Verify your work

```bash
temporal workflow describe -w campaign-summer-splash -o json | jq -r '.workflowExecutionInfo.status'
# WORKFLOW_EXECUTION_STATUS_COMPLETED

# It survived real failures (more than one attempt on publish):
temporal workflow show -w campaign-summer-splash -o json | \
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'   # > 1

# The budget was reserved exactly once, despite the worker kill:
temporal workflow show -w campaign-summer-splash -o json | \
  jq '[.events[] | select(.activityTaskScheduledEventAttributes.activityType.name == "reserve_budget")] | length'   # 1
```

## Stretch (if you have time)

Publish to all three channels **in parallel**: build the three
`execute_activity(...)` coroutines without awaiting them, then
`placements = list(await asyncio.gather(*tasks))` (add `import asyncio` at the
top). If you wrap the call in a helper `async def` instead, remember to
**`return`** the awaited result — `placements` full of `null` is the tell
that your helper awaits but doesn't return. Run it as `campaign-parallel`
and compare the two runs' timelines in the Web UI.

---

*Stuck or want to compare? See the `solution/` directory.*
