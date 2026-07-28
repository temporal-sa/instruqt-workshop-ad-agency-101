# Exercise 4: Retries and typed errors

**Goal:** watch a transient outage recover through Activity retries, then
make a permanent channel rejection fail fast.

Activity failures are retryable by default. Configure retry timing on the
typed proxy:

```ts
retry: {
  initialInterval: '1 second',
  backoffCoefficient: 2,
  maximumInterval: '10 seconds',
}
```

Start the practice Worker, leave AdNet chaos on, and start `publish-1`:

```bash
npx tsx exercises/04-retries-and-errors/practice/worker.ts
temporal workflow start \
  --type publishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-1 \
  --input '"pettok"'
```

After several attempts, recover the service:

```bash
curl -X POST localhost:9999/chaos/off
temporal workflow result -w publish-1
```

Now turn chaos back on and try Dogbook:

```bash
temporal workflow start \
  --type publishWorkflow \
  --task-queue publish-tasks \
  --workflow-id publish-3 \
  --input '"dogbook"'
```

HTTP 403 is permanent. In `practice/activities.ts`, detect 4xx responses
and throw:

```ts
throw ApplicationFailure.nonRetryable(
  `${channel} rejected the post`,
  'ChannelPolicyError',
);
```

Restart the Worker and rerun `publish-3` with
`--id-conflict-policy TerminateExisting`. It should fail after one Activity
attempt. A 5xx remains an ordinary retryable error.

## Verify

```bash
temporal workflow show -w publish-1 -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
temporal workflow show -w publish-3 -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```

The first value must exceed 1; the second must equal 1.
