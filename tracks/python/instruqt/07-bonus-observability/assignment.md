---
slug: bonus-observability
id: k9pyc5jrpfyy
type: challenge
title: '7. Bonus: observability deep dive'
teaser: Read executions like a flight recorder. Meet the Replayer.
notes:
- type: text
  contents: "# This one's a bonus \U0001F381\nThe capstone was the finish line — if
    the clock's run out, you're done,\nand this challenge also lives in the repo for
    your laptop.\n\nHere: event history forensics, and the **Replayer** — the tool
    that\nchecks code changes against histories that already happened."
- type: text
  contents: |-
    # The event history IS the application state
    Every decision your workflow made was recorded: activity scheduled,
    started (with attempt count and last failure), completed (with result).

    **Replay** — what resumed your campaign after the worker kill — is your
    workflow code re-run against those recorded results. Which is why code
    that would issue *different commands* against an old history is an
    error: a **non-determinism error**. The Replayer tests for that before
    you deploy.
tabs:
- id: wejfphfrb8hf
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: qkpizxohztfy
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: fyttxa5gnrgc
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: 8iixbtp98dp8
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: mhxuyxxn0hjn
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: mhmxo8e9myhu
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: 7ugb2giyyeyr
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: intermediate
timelimit: 900
enhanced_loading: null
---

Your capstone run left a perfect flight recording. Let's read it.

# Step 1: Forensics in the UI

Open `campaign-summer-splash` in the [button label="Temporal UI"](tab-5)
and find:

1. **How many attempts** the PetTok publish took — click the
   `ActivityTaskStarted` event for the last `publish_to_channel`; its
   `attempt` field is the counter you watched in challenge 4, and its
   `lastFailure` carries the final 503.
2. **The input** `reserve_budget` received — its `ActivityTaskScheduled`
   event records the payload.
3. **Evidence of your worker kill** — compare the `identity` field on
   `WorkflowTaskStarted` events before and after the kill: two different
   process ids, one workflow.

# Step 2: Forensics in the CLI

Everything the UI shows comes from APIs the CLI can hit too — run these in
the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow list
```

```bash,run
temporal workflow show -w campaign-summer-splash
```

(`--follow` tails a running execution live.)

# Step 3: The Replayer

Export the capstone's history, then replay it against the workflow code
**you** wrote (in the [button label="CLI"](tab-4) tab):

```bash,run
temporal workflow show -w campaign-summer-splash -o json > exercises/07-bonus-observability/history.json
```

```bash,run
uv run exercises/07-bonus-observability/replay.py
```

```nocopy
Replay OK: your workflow code is compatible with the recorded history.
```

That's the test Temporal teams put in CI: replay real production histories
against every code change. Green means "safe to deploy while those
workflows are still running." Hit **Check** once the replay passes.

# Stretch: break it on purpose

In `06-capstone/practice/workflows.py`, swap the order of the
`validate_creative` and `reserve_budget` calls and re-run `replay.py`:

```nocopy
NondeterminismError: ... Activity type of scheduled event 'validate_creative'
does not match activity type of activity command 'reserve_budget'
```

The history says the first command was `validate_creative`; your edited
code now leads with `reserve_budget`. Replay refuses to guess. (Subtle
nugget: replay compares the *sequence of command types* — swapping two
publishes to different channels would NOT trip it, since both are the same
`publish_to_channel` activity. Structure is compared; arguments aren't.)

**Revert the edit** and re-run until you see `Replay OK` again.

# Where to next

- [learn.temporal.io](https://learn.temporal.io) — Temporal 101/102 with
  Python pick up exactly where this workshop ends: testing, debugging,
  deployment, versioning.
- [docs.temporal.io](https://docs.temporal.io) — concepts and Python SDK.
