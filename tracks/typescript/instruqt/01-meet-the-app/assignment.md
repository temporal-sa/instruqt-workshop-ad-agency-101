---
slug: meet-the-app
type: challenge
title: 1. Meet the app (and watch it die)
teaser: Launch a campaign with plain TypeScript. Lose everything mid-flight.
notes:
- type: text
  contents: |-
    # Exercise 1: Meet the app (and watch it die)
    run the existing TypeScript campaign launcher and see why ordinary process state is not durable.
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

**Goal:** run the existing TypeScript campaign launcher and see why ordinary
process state is not durable.

# Step 1: Start the services

In the [button label="AdNet"](tab-2) tab, start the ad network:

```bash,run
.adnet-venv/bin/python services/adnet.py
```

In the [button label="Server"](tab-1) tab, start the Temporal dev server:

```bash,run
temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --db-filename temporal.db
```

Now open the [button label="Temporal UI"](tab-5) tab. It works now, and
there are no Workflows yet.

> [!IMPORTANT]
> Leave AdNet and the Temporal dev server running for the whole workshop.
> Their terminal tabs use persistent sessions.

# Step 2: Launch the campaign

Skim `01-meet-the-app/practice/app.ts` in the
[button label="Editor"](tab-0) tab. Then run it in the
[button label="CLI"](tab-4) tab:

```bash,run
npx tsx exercises/01-meet-the-app/practice/app.ts
```

The launcher validates the creative, reserves $50,000, publishes to Meowta
and Catstagram, then crashes when PetTok returns HTTP 503. The `placements`
array lived only in Node.js memory, so the process lost its progress.

Re-running is unsafe: it reserves the budget and publishes successful
channels again. By exercise 6, the same sequence will be a Temporal
Workflow that recovers after the Worker process dies.

# Step 3: Verify the services

In the [button label="CLI"](tab-4) tab:

```bash,run
curl -sf localhost:9999/health
```

```bash,run
temporal operator cluster health
```

When both commands succeed, hit **Check**.
