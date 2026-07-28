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

Export the capstone history:

```bash
temporal workflow show -w campaign-summer-splash -o json \
  > exercises/07-bonus-observability/history.json
```

Replay it:

```bash
mvn -q -f exercises/07-bonus-observability/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.Replay
```

`WorkflowReplayer` compares commands produced by
`CampaignWorkflowImpl` with recorded Event History. It does not call real
Activities.

As an experiment, reorder budget reservation and creative validation,
rerun replay, and observe `NonDeterministicException`. Restore the original
order afterward.

```bash
temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```
