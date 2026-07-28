# Exercise 2: Your first workflow

**Goal:** define a workflow, run a worker, and start an execution from the
CLI. Marketing needs a tagline for Summer Splash — we'll make Temporal
deliver it.

## Concepts

**Workflow definition.** A workflow is Python code that orchestrates a
business process. In the Python SDK it's a class marked `@workflow.defn`
whose entry point is an async method marked `@workflow.run`. Temporal records
everything the workflow does, which is what makes it durable — and it's also
why workflow code must be deterministic (no network calls, no disk I/O; that
work belongs in *activities*, coming in exercise 3).

**Worker.** Temporal's server never runs your code. A **worker** — a plain
Python process *you* run — polls the server for tasks and executes your
workflow code. No worker, no progress: workflows just wait patiently on the
queue. (This is also Temporal's superpower, as you'll see in the capstone.)

**Task queue.** The named rendezvous point between starters and workers. You
start a workflow *on* a task queue; workers poll *from* it. The names must
match exactly — this is the #1 "why is nothing happening?" in all of
Temporal.

**Starting a workflow.** Any Temporal client can start one. Today we'll use
the `temporal` CLI; application code uses the SDK's client the same way.

## Part A: Read the code

Open `exercises/02-first-workflow/practice/`:

- `workflows.py` — `TaglineWorkflow`, nearly complete
- `worker.py` — connects to the server, registers the workflow, polls a task
  queue

## Part B: Finish the workflow

In `practice/workflows.py`, replace the `TODO` so the workflow returns the
brand name, a colon and a space, then `Taste the Meow!`:

```
"CatNip Cola: Taste the Meow!"
```

## Part C: Finish the worker, then run it

In `practice/worker.py`, fill in the task queue name: the starter command in
Part D targets `tagline-tasks`. Then start your worker:

```bash
uv run exercises/02-first-workflow/practice/worker.py
```

Leave it running. It prints one line and then sits there — that's a worker
doing its job (polling).

## Part D: Start it from the CLI

In another terminal:

```bash
temporal workflow start \
  --type TaglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id tagline-1 \
  --input '"CatNip Cola"'
```

Note what each flag is: the workflow **type** (your class name), the **task
queue** (must match the worker), a **workflow ID** you choose (a business
identifier — more on this in the capstone), and the **input** (JSON — hence
the quoted quotes).

Get the result:

```bash
temporal workflow result -w tagline-1
```

Then go look at it in the Web UI ([http://localhost:8233](http://localhost:8233)):
click into `tagline-1`, and open the **Input and Results** section. Skim the
event history below it — `WorkflowExecutionStarted`, `WorkflowTaskScheduled`,
`...Started`, `...Completed`. That history *is* the durability mechanism, and
exercise 7 digs into it.

## Verify your work

```bash
temporal workflow describe -w tagline-1 -o json | jq -r '.workflowExecutionInfo.status'
# WORKFLOW_EXECUTION_STATUS_COMPLETED
temporal workflow result -w tagline-1
# "CatNip Cola: Taste the Meow!"
```

## Stretch (if you have time)

- Read the full event history from the CLI: `temporal workflow show -w tagline-1`
- Start `tagline-2` with a different brand as input. Marketing says
  `"Doggy Paddle Water"` is the next big thing.
- Stop your worker (Ctrl-C), start `tagline-3`, and watch it sit in
  **Running** in the UI — nobody's home on the task queue. Start the worker
  and watch it complete instantly.

---

*Stuck or want to compare? See the `solution/` directory.*
