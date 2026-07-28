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

# Step 1: Trace the worked Activity

In the [button label="Editor"](tab-0) tab, open
`03-activities/practice/`:

- `TaglineActivities` defines the Activity contract.
- `TaglineActivitiesImpl` performs the AdNet request.
- `SocialPostWorkflowImpl` creates a typed `taglineActivities` stub and
  calls `generateTagline`.
- `SocialPostWorker` registers `new TaglineActivitiesImpl()`.

That is the complete path: Activity interface → implementation → typed
Workflow stub → Worker registration.

# Step 2: Complete `fetchHashtags`

In `HashtagActivitiesImpl.java`, finish `fetchHashtags`. The HTTP request
and JSON decoding are already provided. Read `hashtags` from the decoded
map and return it:

```java
@SuppressWarnings("unchecked")
List<String> hashtags = (List<String>) body.get("hashtags");
return hashtags;
```

# Step 3: Call the Activity from the Workflow

Open `SocialPostWorkflowImpl.java`. The `hashtagActivities` typed stub is
already scaffolded above `createPost`. Inside `createPost`, replace the
empty list:

```java
List<String> hashtags = List.of();
```

with the Activity call:

```java
List<String> hashtags = hashtagActivities.fetchHashtags(channel);
```

This does not call `HashtagActivitiesImpl` directly. The typed stub tells
Temporal to schedule a `fetchHashtags` Activity Task and wait durably for
its result.

# Step 4: Register the implementation

Open `SocialPostWorker.java` and add the new implementation to the existing
registration:

```java
worker.registerActivitiesImplementations(
    new TaglineActivitiesImpl(),
    new HashtagActivitiesImpl());
```

The Workflow stub schedules the task; this registered implementation is
what lets the Worker execute it.

# Step 5: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
mvn -q -f exercises/03-activities/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.SocialPostWorker
```

# Step 6: Start the Workflow

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
