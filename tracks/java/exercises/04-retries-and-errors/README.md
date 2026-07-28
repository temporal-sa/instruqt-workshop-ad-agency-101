# Exercise 4: Retries and typed errors

**Goal:** recover from a transient outage with Activity retries, then make a
permanent channel rejection fail fast.

Add `RetryOptions` to `PublishWorkflowImpl`:

```java
RetryOptions.newBuilder()
    .setInitialInterval(Duration.ofSeconds(1))
    .setBackoffCoefficient(2)
    .setMaximumInterval(Duration.ofSeconds(10))
    .build()
```

# Step 1: Publish into the outage

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
mvn -q -f exercises/04-retries-and-errors/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.PublishWorker
```

Leave AdNet chaos on. In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-1 \
  --input '"pettok"'
```

Open `publish-1` in the [button label="Temporal UI"](tab-5) tab. Under
**Pending Activities**, watch its attempt count increase. The
[button label="Worker"](tab-3) tab shows each failed attempt without the
Worker process crashing.

# Step 2: Recover the service

After several attempts, use the [button label="CLI"](tab-4) tab:

```bash,run
curl -X POST localhost:9999/chaos/off
```

```bash,run
temporal workflow result -w publish-1
```

# Step 3: Add the retry policy

In the [button label="Editor"](tab-0) tab, add the shown `RetryOptions` in
`PublishWorkflowImpl`. Restart the Worker in the
[button label="Worker"](tab-3) tab after every code change.

# Step 4: See when retrying is wrong

Dogbook always returns HTTP 403. In the [button label="CLI"](tab-4) tab,
start it once to observe the default retry behavior:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-2 \
  --input '"dogbook"'
```

After confirming the retries in the [button label="Temporal UI"](tab-5)
tab, terminate the execution in the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow terminate -w publish-2 --reason "retrying a permanent failure"
```

In `PublishActivitiesImpl` in the [button label="Editor"](tab-0) tab,
detect 4xx responses and throw:

```java
throw ApplicationFailure.newNonRetryableFailure(
    channel + " rejected the post",
    "ChannelPolicyError");
```

Restart the Worker in the [button label="Worker"](tab-3) tab, then use the
[button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-3 \
  --input '"dogbook"'
```

It must fail after one Activity attempt, while 5xx failures remain retryable.
Prove success still works:

```bash,run
temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-ok \
  --input '"meowta"'
```

```bash,run
temporal workflow result -w publish-ok
```

When `publish-1` completed, `publish-3` failed fast, and `publish-ok`
completed, hit **Check**.

> [!NOTE]
> Stuck? Compare with `04-retries-and-errors/solution/` in the
> [button label="Editor"](tab-0) tab.
