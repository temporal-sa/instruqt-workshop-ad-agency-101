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

1. In `TaglineWorkflowImpl.java`, return `brand + ": Taste the Meow!"`.
2. In `TaglineWorker.java`, use Task Queue `tagline-tasks`.
3. Start the Worker:

```bash
mvn -q -f exercises/02-first-workflow/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.TaglineWorker
```

In another terminal:

```bash
temporal workflow start \
  --type TaglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id tagline-1 \
  --input '"CatNip Cola"'
temporal workflow result -w tagline-1
```

The Workflow type defaults to the annotated interface name. Expected result:
`"CatNip Cola: Taste the Meow!"`.
