# Exercise 4: Retries and typed errors

**Goal:** watch a transient outage recover through Activity retries, then
make a permanent channel rejection fail fast.

Activity failures are retryable by default. Configure retry timing with a
`Temporalio::RetryPolicy` passed to `execute_activity`:

```ruby
retry_policy: Temporalio::RetryPolicy.new(
  initial_interval: 1,
  backoff_coefficient: 2,
  max_interval: 10
)
```

Durations are in seconds.

# Step 1: Publish into the outage

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
bundle exec ruby exercises/04-retries-and-errors/practice/worker.rb
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

In the [button label="Editor"](tab-0) tab, add the shown `retry_policy:` to
the `execute_activity` call in `04-retries-and-errors/practice/workflows.rb`. Restart
the Worker in the [button label="Worker"](tab-3) tab after every code change.

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

After confirming the pointless retries in the
[button label="Temporal UI"](tab-5) tab, terminate that execution from the
[button label="CLI"](tab-4) tab:

```bash,run
temporal workflow terminate -w publish-2 --reason "retrying a permanent failure"
```

In `04-retries-and-errors/practice/activities.rb` in the
[button label="Editor"](tab-0) tab, detect 4xx responses and raise:

```ruby
status = response.code.to_i
if status >= 400 && status < 500
  raise Temporalio::Error::ApplicationError.new(
    "#{channel} rejected the post",
    type: 'ChannelPolicyError',
    non_retryable: true
  )
end
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

It should fail after one Activity attempt. A 5xx remains an ordinary
retryable error.

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

# Step 5: Verify the attempts

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow show -w publish-1 -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```

```bash,run
temporal workflow show -w publish-3 -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```

The first value must exceed 1; the second must equal 1.

When `publish-1` completed, `publish-3` failed fast, and `publish-ok`
completed, hit **Check**.

> [!NOTE]
> Stuck? Compare with `04-retries-and-errors/solution/` in the
> [button label="Editor"](tab-0) tab.
