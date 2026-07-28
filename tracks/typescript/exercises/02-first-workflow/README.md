# Exercise 2: Your first Workflow

**Goal:** finish a Workflow function, register it with a Worker, and start
it from the Temporal CLI.

In the TypeScript SDK, an exported async function is a Workflow definition.
Temporal bundles Workflow code into an isolated deterministic runtime. A
Worker polls a Task Queue and runs that code; the Temporal Service never
runs your application code.

1. In `practice/workflows.ts`, return
   `` `${brand}: Taste the Meow!` ``.
2. In `practice/worker.ts`, set `taskQueue` to `tagline-tasks`.
3. Start the Worker:

```bash
npx tsx exercises/02-first-workflow/practice/worker.ts
```

In another terminal:

```bash
temporal workflow start \
  --type taglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id tagline-1 \
  --input '"CatNip Cola"'

temporal workflow result -w tagline-1
```

The Workflow type is the exported function name. The Task Queue must match
the Worker exactly. The Workflow ID is the durable business identifier for
this execution.

## Verify

```bash
temporal workflow describe -w tagline-1 -o json |
  jq -r '.workflowExecutionInfo.status'
temporal workflow result -w tagline-1
```

Expected result: `"CatNip Cola: Taste the Meow!"`.
