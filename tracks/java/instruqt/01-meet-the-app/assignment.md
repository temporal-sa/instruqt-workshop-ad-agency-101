---
slug: meet-the-app
type: challenge
title: 1. Meet the app (and watch it die)
teaser: Launch a campaign with plain Java. Lose everything mid-flight.
notes:
- type: text
  contents: |-
    # Exercise 1: Meet the app (and watch it die)
    run the existing Java campaign launcher and see why ordinary process state is not durable.
tabs:
- id: rmtkrgx7el6v
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: fnx31axbiv6l
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: 647wels483vv
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: 2yicx0uvd9js
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: mx5b801s9lf4
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: 9svo23sersy8
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: hviajx29gtps
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: basic
timelimit: 900
enhanced_loading: null
---

# Exercise 1: Meet the app (and watch it die)

**Goal:** run the existing Java campaign launcher and see why ordinary
process state is not durable.

Use three terminals from the track root:

```bash
# Terminal 1
.adnet-venv/bin/python services/adnet.py

# Terminal 2
temporal server start-dev --db-filename temporal.db

# Terminal 3
mvn -q -f exercises/01-meet-the-app/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.CampaignApp
```

The launcher validates the creative, reserves $50,000, publishes to Meowta
and Catstagram, then throws when PetTok returns HTTP 503. Its local list of
placements disappears with the JVM.

Re-running is unsafe: it repeats the budget reservation and successful
publications. By exercise 6, the same sequence will be a Temporal Workflow
that recovers after the Worker process dies.

## Verify

```bash
curl -sf localhost:9999/health
temporal operator cluster health
```
