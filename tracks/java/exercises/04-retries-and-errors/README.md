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

Start the Worker and a PetTok run while chaos is on:

```bash
mvn -q -f exercises/04-retries-and-errors/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.PublishWorker

temporal workflow start \
  --type PublishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-1 \
  --input '"pettok"'
```

After several attempts:

```bash
curl -X POST localhost:9999/chaos/off
temporal workflow result -w publish-1
```

Dogbook returns HTTP 403 forever. In `PublishActivitiesImpl`, detect 4xx and
throw:

```java
throw ApplicationFailure.newNonRetryableFailure(
    channel + " rejected the post",
    "ChannelPolicyError");
```

Restart the Worker and run `publish-3` against Dogbook. It must fail after
one Activity attempt, while 5xx failures remain retryable.
