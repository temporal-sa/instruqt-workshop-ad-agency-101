# Exercise 3: Activities

**Goal:** move network I/O into an Activity implementation and call it from
a Workflow through a typed stub.

Java Workflow code has no sandbox. Never perform network, file, database,
clock, random, or thread operations in it. Put side effects in an
`@ActivityInterface` implementation and create a stub:

```java
HashtagActivities activities =
    Workflow.newActivityStub(
        HashtagActivities.class,
        ActivityOptions.newBuilder()
            .setStartToCloseTimeout(Duration.ofSeconds(10))
            .build());
```

# Step 1: Complete and register the Activity

In the [button label="Editor"](tab-0) tab:

1. Implement `HashtagActivitiesImpl.fetchHashtags`: GET
   `/trending/<channel>`, decode JSON, and return the hashtag list.
2. In `SocialPostWorkflowImpl`, call it with the incoming channel.
3. In `SocialPostWorker`, register `new HashtagActivitiesImpl()`.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
mvn -q -f exercises/03-activities/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.SocialPostWorker
```

# Step 3: Start the Workflow

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type SocialPostWorkflow \
  --task-queue social-tasks \
  --workflow-id social-post-1 \
  --input '"catstagram"'
```

```bash,run
temporal workflow result -w social-post-1
```

The result must contain `#CatsOfCatstagram` and `#SummerSplash`. If the
Activity implementation is not registered, the Activity remains pending
and the Worker reports that its type is unknown.

Open `social-post-1` in the [button label="Temporal UI"](tab-5) tab and find
both completed Activities in Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `03-activities/solution/` in the
> [button label="Editor"](tab-0) tab.
