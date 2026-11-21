# Exercise 2: Your first Workflow

**Goal:** finish a Workflow class, register it with a Worker, and start it
from the Temporal CLI.

In the .NET SDK, a Workflow is a class marked `[Workflow]` with one
`[WorkflowRun]` entry method:

```csharp
[Workflow]
public class TaglineWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string brand) => ...;
}
```

The .NET SDK has no sandbox, so Workflow code must stay deterministic by
design: no I/O, `Task.Run`, `Task.Delay`, `DateTime.Now`, or random numbers.
A Worker polls a Task Queue and runs this code; the Temporal Service never
runs your application code.

# Step 1: Finish the code

In the [button label="Editor"](tab-0) tab, open
`02-first-workflow/practice/`:

1. In `TaglineWorkflow.workflow.cs`, return
   `$"{brand}: Taste the Meow!"`.
2. In `Program.cs`, set the Worker's `taskQueue` to `tagline-tasks`.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab:

```bash,run
dotnet run --project exercises/02-first-workflow/practice/TaglineWorker.csproj
```

Wait for `Worker started on task queue 'tagline-tasks'`.

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

The Workflow type defaults to the class name. The Task Queue must match the
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
