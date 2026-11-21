# Exercise 2: Your first Workflow

**Goal:** finish a Workflow class, register it with a Worker, and start it
from the Temporal CLI.

In the Ruby SDK, a Workflow is a class that subclasses
`Temporalio::Workflow::Definition` and implements `execute`:

```ruby
class TaglineWorkflow < Temporalio::Workflow::Definition
  def execute(brand)
    # ...
  end
end
```

The Temporal Service never runs this code. A Worker polls a Task Queue and
runs registered Workflow classes on a deterministic fiber scheduler.

# Step 1: Finish the code

In the [button label="Editor"](tab-0) tab, open
`02-first-workflow/practice/`:

1. In `workflows.rb`, return `"#{brand}: Taste the Meow!"`.
2. In `worker.rb`, set `task_queue` to `'tagline-tasks'`.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab:

```bash,run
bundle exec ruby exercises/02-first-workflow/practice/worker.rb
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

The Workflow type defaults to the class name. The Task Queue must match
the Worker exactly. The Workflow ID is the durable business identifier for
this execution.

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
