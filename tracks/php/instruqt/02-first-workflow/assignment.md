---
slug: first-workflow
type: challenge
title: 2. Your first workflow
teaser: A workflow, a worker, a task queue — and a tagline for marketing.
notes:
- type: text
  contents: |-
    # Exercise 2: Your first Workflow
    finish a Workflow class, register it with a Worker, and start it from the Temporal CLI.
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

# Exercise 2: Your first Workflow

**Goal:** finish a Workflow class, register it with a Worker, and start it
from the Temporal CLI.

In the PHP SDK, a class marked `#[WorkflowInterface]` is a Workflow
definition, and its `#[WorkflowMethod]` is the entry point:

```php
#[WorkflowInterface]
final class TaglineWorkflow
{
    #[WorkflowMethod]
    public function run(string $brand): string
    {
        // ...
    }
}
```

A Worker polls a Task Queue and runs that code; the Temporal Service never
runs your application code. PHP Workers run under RoadRunner: the `rr`
binary connects to Temporal and starts your `worker.php` as a pool of PHP
processes.

# Step 1: Finish the code

In the [button label="Editor"](tab-0) tab, open
`02-first-workflow/practice/`:

1. In `TaglineWorkflow.php`, return `"{$brand}: Taste the Meow!"`.
2. In `worker.php`, create the Worker for Task Queue `tagline-tasks`.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab:

```bash,run
rr serve -o server.command="php exercises/02-first-workflow/practice/worker.php"
```

RoadRunner reads the connection settings from `.rr.yaml` in the workshop
directory. The `-o` override picks this exercise's `worker.php`. Wait for
`RoadRunner server started`.

# Step 3: Start the Workflow

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type TaglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id tagline-1 \
  --input '"CatNip Cola"'
```

```bash,run
temporal workflow result -w tagline-1
```

The Workflow Type defaults to the class name. The Task Queue must match the
Worker exactly. The Workflow ID is the durable business identifier for this
execution.

# Step 4: Inspect the execution

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow describe -w tagline-1 -o json |
  jq -r '.workflowExecutionInfo.status'
```

```bash,run
temporal workflow result -w tagline-1
```

Expected result: `"CatNip Cola: Taste the Meow!"`.

Open `tagline-1` in the [button label="Temporal UI"](tab-5) tab and inspect
its input, result, and Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `02-first-workflow/solution/` in the
> [button label="Editor"](tab-0) tab.
