---
slug: first-workflow
id: r9wa85xdfdsm
type: challenge
title: 2. Your first workflow
teaser: A workflow, a worker, a task queue — and a tagline for marketing.
notes:
- type: text
  contents: |-
    # Concepts for this challenge
    - **Workflow** — durable orchestration code: a class with `@workflow.defn`,
      an async `@workflow.run` entry point. Temporal records everything it does.
    - **Worker** — a plain Python process *you* run. It polls the server for
      tasks and executes your code. The server never runs your code.
    - **Task queue** — the named rendezvous between starters and workers.
      The names must match *exactly*.
- type: text
  contents: "# The #1 \"why is nothing happening?\"\nA workflow started on task queue
    `tagline-tasks` waits forever unless a\nworker is polling `tagline-tasks`. Mismatched
    task queue names are the\nmost common beginner trip-up in all of Temporal. You
    have been warned. \U0001F408"
tabs:
- id: pwyeki5oexku
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: hwqss9aitkuw
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: ybdexyd7gnne
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: qsqswl9jemzr
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: e7hhxtczdzdi
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: yuef90y6wmcn
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: xniyyrfwsm2q
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: basic
timelimit: 900
enhanced_loading: null
---

Marketing needs a tagline for Summer Splash. We'll make Temporal deliver it —
your first workflow, worker, and CLI-started execution.

# Step 1: Read the code

In the [button label="Editor"](tab-0) tab, open `02-first-workflow/practice/`:

- `workflows.py` — `TaglineWorkflow`, nearly complete
- `worker.py` — connects to the server, registers the workflow, polls a
  task queue

# Step 2: Finish the workflow

In `02-first-workflow/practice/workflows.py`, replace the `TODO` so the workflow returns the
brand name, a colon and a space, then `Taste the Meow!`:

```nocopy
"CatNip Cola: Taste the Meow!"
```

# Step 3: Finish the worker, then run it

In `02-first-workflow/practice/worker.py`, fill in the task queue name — the starter command
in Step 4 targets `tagline-tasks`. Then, in the [button label="Worker"](tab-3) tab:

```bash,run
uv run exercises/02-first-workflow/practice/worker.py
```

It prints one line and sits there. That's a worker doing its job: polling.

# Step 4: Start it from the CLI

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type TaglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id tagline-1 \
  --input '"CatNip Cola"'
```

Note the four flags: the workflow **type** (your class name), the **task
queue** (must match the worker), a **workflow ID** you choose, and the
**input** (JSON — hence the quoted quotes). Get the result:

```bash,run
temporal workflow result -w tagline-1
```

Then find `tagline-1` in the [button label="Temporal UI"](tab-5): open
**Input and Results**, and skim the event history —
`WorkflowExecutionStarted`, `WorkflowTaskScheduled`, `...Completed`. That
history *is* the durability mechanism.

When `tagline-1` has completed with the right tagline, hit **Check**.

# Stretch (if you have time)

- Read the history from the CLI: `temporal workflow show -w tagline-1`
- Start `tagline-2` with input `"Doggy Paddle Water"` (marketing says it's
  the next big thing)
- Ctrl-C your worker, start `tagline-3`, watch it sit **Running** in the
  [button label="Temporal UI"](tab-5) (nobody's polling!), then restart the worker and watch it finish instantly.

> [!NOTE]
> Stuck? Compare with `02-first-workflow/solution/` in the [button label="Editor"](tab-0) tab.
