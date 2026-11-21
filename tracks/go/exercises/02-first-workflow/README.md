# Exercise 2: Your first Workflow

**Goal:** finish a Workflow function, register it with a Worker, and start
it from the Temporal CLI.

In the Go SDK, a Workflow Definition is an exported function whose first
parameter is `workflow.Context`:

```go
func TaglineWorkflow(ctx workflow.Context, brand string) (string, error)
```

The Temporal Service never runs this code. A Worker polls a Task Queue and
executes the Workflow functions registered with it.

# Step 1: Finish the code

In the [button label="Editor"](tab-0) tab, open
`02-first-workflow/practice/`:

1. In `workflow.go`, return `brand + ": Taste the Meow!", nil`.
2. In `worker/main.go`, set `taskQueue` to `"tagline-tasks"`.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab:

```bash,run
go run ./exercises/02-first-workflow/practice/worker
```

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

The Workflow Type defaults to the function name. The Task Queue must match
the Worker exactly. The Workflow ID is the durable business identifier for
this execution. Expected result: `"CatNip Cola: Taste the Meow!"`.

Open `tagline-1` in the [button label="Temporal UI"](tab-5) tab and inspect
its input, result, and Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `02-first-workflow/solution/` in the
> [button label="Editor"](tab-0) tab.
