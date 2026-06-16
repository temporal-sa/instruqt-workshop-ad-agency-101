# Exercise 7 (bonus): Observability deep dive

**Goal:** read an execution like a flight recorder, and meet the Replayer —
the tool that checks code changes against histories that already happened.

This one's a bonus: if the workshop clock has run out, the capstone was the
finish line — take this home and run it on your laptop. Everything here
works against the `campaign-summer-splash` execution you already ran.

## Concepts

**The event history is the application state.** Every decision your workflow
made was recorded as a command and stored as an event: activity scheduled,
started (with attempt number and last failure), completed (with the result
payload). Replay — the mechanism that resumed your campaign after the worker
kill — is just re-running your workflow code while feeding it recorded
results from this history instead of re-executing activities.

**Which is why determinism matters.** If your code, re-run against an old
history, would issue *different commands* than the history shows, replay
can't proceed — that's a **non-determinism error**. The Replayer lets you
test for that *before* deploying changed code.

## Part A: Forensics in the UI

Open `campaign-summer-splash` in the Web UI and find:

1. **How many attempts** did the PetTok publish take? (Click into the
   `ActivityTaskStarted` event for the last `publish_to_channel` — its
   `attempt` field is the number you watched climb in exercise 4. Its
   `lastFailure` carries the final 503 message.)
2. **The input** `reserve_budget` received. (Its `ActivityTaskScheduled`
   event records the input payload — `"summer-splash"`.)
3. **Evidence of your worker kill**: compare the `identity` field on
   `WorkflowTaskStarted` events before and after the kill — two different
   process ids. The same workflow, executed by two different workers.

## Part B: Forensics in the CLI

Everything the UI shows comes from APIs the CLI can hit too:

```bash
temporal workflow list
temporal workflow show -w campaign-summer-splash         # the full history
temporal workflow show -w campaign-summer-splash --follow  # tails a running one
```

## Part C: The Replayer

Export the history, then replay it against the workflow code you wrote in
the capstone:

```bash
temporal workflow show -w campaign-summer-splash -o json \
  > exercises/07-bonus-observability/history.json
uv run exercises/07-bonus-observability/replay.py
```

```
Replay OK: your workflow code is compatible with the recorded history.
```

That's the test Temporal teams put in CI: replay a corpus of real production
histories against every code change. Green means "safe to deploy while those
workflows are still running."

## Stretch: break it on purpose

In your `exercises/06-capstone/practice/workflows.py`, swap the order of the
`validate_creative` and `reserve_budget` calls — reserve first, validate
second — and re-run `replay.py`. You'll get:

```
NondeterminismError: ... Activity type of scheduled event 'validate_creative'
does not match activity type of activity command 'reserve_budget'
```

The history says event #7 was `validate_creative`; your edited code's first
command is now `reserve_budget`. Replay refuses to guess. (Subtle nugget:
replay compares the *sequence of commands* — swapping two publishes to
different channels would NOT trip it, because both are the same
`publish_to_channel` activity type. Arguments aren't compared, structure is.)

**Now revert the edit** and re-run `replay.py` until you see `Replay OK`
again — never leave your workflow code incompatible with its own past.

## Where to next

- [learn.temporal.io](https://learn.temporal.io) — the full free course path
  (Temporal 101 and 102 with Python pick up exactly where this workshop ends:
  testing, debugging, deployment, versioning)
- [docs.temporal.io](https://docs.temporal.io) — concepts and Python SDK docs
