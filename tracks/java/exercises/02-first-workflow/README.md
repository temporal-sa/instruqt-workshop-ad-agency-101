# Exercise 2: Your first Workflow

**Goal:** finish a Workflow implementation, register it with a Worker, and
start it from the Temporal CLI.

The Java SDK uses an interface plus implementation:

```java
@WorkflowInterface
public interface TaglineWorkflow {
  @WorkflowMethod
  String generate(String brand);
}
```

Temporal's Service never runs this code. A Worker polls a Task Queue and
executes registered implementation classes.

# Step 1: Finish the code

In the [button label="Editor"](tab-0) tab, open
`02-first-workflow/practice/`:

1. In `TaglineWorkflowImpl.java`, return `brand + ": Taste the Meow!"`.
2. In `TaglineWorker.java`, use Task Queue `tagline-tasks`.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab:

```bash,run
mvn -q -f exercises/02-first-workflow/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.TaglineWorker
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

The Workflow type defaults to the annotated interface name. Expected result:
`"CatNip Cola: Taste the Meow!"`.

Open `tagline-1` in the [button label="Temporal UI"](tab-5) tab and inspect
its input, result, and Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `02-first-workflow/solution/` in the
> [button label="Editor"](tab-0) tab.
