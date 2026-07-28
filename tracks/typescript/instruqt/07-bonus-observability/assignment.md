---
slug: bonus-observability
type: challenge
title: '7. Bonus: observability deep dive'
teaser: Read executions like a flight recorder. Meet the Replayer.
notes:
- type: text
  contents: |-
    # Exercise 7: Bonus — Event History and replay
    inspect the durable record and replay it against current Workflow code.
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

# Exercise 7: Bonus — Event History and replay

**Goal:** inspect the durable record and replay it against current Workflow
code.

Export the completed capstone history:

```bash
temporal workflow show -w campaign-summer-splash -o json \
  > exercises/07-bonus-observability/history.json
```

Replay against your `practice/workflows.ts`:

```bash
npx tsx exercises/07-bonus-observability/replay.ts
```

`Worker.runReplayHistory` executes Workflow code against the recorded
commands without calling the real Activities. Success means the current
Workflow remains deterministic and compatible with that history.

As an experiment, reorder `reserveBudget` and `validateCreative`, rerun the
replay, and observe the non-determinism error. Restore the order afterward.

Useful history queries:

```bash
temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].eventType] | group_by(.) | map({event: .[0], count: length})'

temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```
