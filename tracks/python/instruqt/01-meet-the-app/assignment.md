---
slug: meet-the-app
id: 0b9mbampuncq
type: challenge
title: 1. Meet the app (and watch it die)
teaser: Launch a campaign with plain Python. Lose everything mid-flight.
notes:
- type: text
  contents: "# CatNip Cola: Summer Splash \U0001F964\U0001F408\nYou're the platform
    engineer at an ad agency. Marketing wants the\ncampaign live on **Meowta**, **Catstagram**
    and **PetTok** today.\n\nThe current launcher is a plain Python script. Let's
    see how that goes."
- type: text
  contents: |-
    # Your workbench
    - **Editor** — the workshop code (`practice/` is yours, `solution/` is the answer key)
    - **Server** / **AdNet** — one terminal per long-running service
    - **Worker** / **CLI** — your working terminals
    - **Temporal UI** — the Web UI (it'll error until you start the server — that's your first job)
    - **Download** — take the whole workshop home as a zip, any time
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

Your job: run the campaign launcher the way it exists today, watch it fail
halfway, and take stock of what was lost.

# Step 1: Start the services

In the [button label="AdNet"](tab-2) tab, start the ad network:

```bash,run
uv run services/adnet.py
```

In the [button label="Server"](tab-1) tab, start the Temporal dev server:

```bash,run
temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0 --db-filename temporal.db
```

Now open the [button label="Temporal UI"](tab-5) tab — it works now, and
it's empty. No workflows yet. We'll fix that in the next challenge.

> [!IMPORTANT]
> Leave both services running for the entire workshop. The terminal tabs are
> persistent sessions: what you start here keeps running as you move between
> challenges. If a service ever does die, restart it with the same command.

# Step 2: Launch the campaign

The launcher does four things in order: validate the creative, reserve
**$50,000** of client budget, publish to each of the three channels, and
file a launch report. Skim it in the [button label="Editor"](tab-0) tab
(`01-meet-the-app/practice/app.py`), then run it in the [button label="CLI"](tab-4) tab:

```bash,run
uv run exercises/01-meet-the-app/practice/app.py
```

Watch it go: creative approved ✅, budget reserved 💸, live on Meowta 📣,
live on Catstagram 📣... and then a `503 Server Error` traceback from
PetTok. (PetTok's ads API is, quote, "on fire." AdNet's chaos mode did
that, and it's staying on — it's the curriculum.)

# Step 3: The damage report

The process is dead. Consider:

- **$50,000 is reserved.** Nothing is tracking that.
- **The campaign is live on 2 of 3 channels.** The only record was in local
  variables that died with the process.
- **Can you just re-run it?** Look at the code: it starts from the top.
  Re-running reserves *another* $50k and re-publishes to channels that are
  already live.

The usual fix is to hand-build state tables, status columns, retry wrappers
and recovery cron jobs around the script. The rest of this workshop builds
the alternative: by challenge 6, this exact file becomes a Temporal
workflow that shrugs off this crash.

When both services are running, hit **Check**.
