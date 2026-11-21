# Exercise 6: Capstone — make the campaign durable

**Goal:** rebuild the fragile exercise-1 launcher as a Temporal Workflow,
then kill its Worker during a retry.

The Ruby mapping is:

| Before | Temporal |
|---|---|
| plain Ruby method | `Temporalio::Activity::Definition` subclass |
| direct method call | `Temporalio::Workflow.execute_activity` |
| `each` / `map` loop | deterministic Workflow orchestration |
| raised HTTP error | retryable or non-retryable `ApplicationError` |

# Step 1: Build the durable application

Use the [button label="Editor"](tab-0) tab:

1. In `practice/activities.rb`, make each of the four classes subclass
   `Temporalio::Activity::Definition`.
2. In `practice/workflows.rb`, schedule each Activity with
   `Temporalio::Workflow.execute_activity` and a ten-second
   `start_to_close_timeout`. Give `PublishToChannel` this retry policy:

```ruby
retry_policy: Temporalio::RetryPolicy.new(
  initial_interval: 1,
  backoff_coefficient: 2,
  max_interval: 10,
  non_retryable_error_types: ['ChannelPolicyError']
)
```

3. Rebuild the original sequence by running `ValidateCreative`,
   `ReserveBudget`, `PublishToChannel` for each channel in order, and
   `GenerateLaunchReport`.
4. In `PublishToChannel`, convert 4xx responses to a non-retryable
   `Temporalio::Error::ApplicationError` of type `ChannelPolicyError`.
5. In `practice/worker.rb`, replace the empty `activities:` list with the
   four Activity classes.

# Step 2: Launch through the outage

In the [button label="CLI"](tab-4) tab, turn chaos on:

```bash,run
curl -X POST localhost:9999/chaos/on
```

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
bundle exec ruby exercises/06-capstone/practice/worker.rb
```

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type CampaignWorkflow \
  --task-queue campaign-tasks \
  --workflow-id campaign-summer-splash \
  --input '"summer-splash"'
```

# Step 3: Kill the Worker

Open `campaign-summer-splash` in the
[button label="Temporal UI"](tab-5) tab. Wait until PetTok is retrying,
then go to the [button label="Worker"](tab-3) tab and press Ctrl-C.

Inspect the execution from the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow describe -w campaign-summer-splash
```

It remains Running.

# Step 4: Recover

Restart the Worker in the [button label="Worker"](tab-3) tab:

```bash,run
bundle exec ruby exercises/06-capstone/practice/worker.rb
```

Recover AdNet from the [button label="CLI"](tab-4) tab:

```bash,run
curl -X POST localhost:9999/chaos/off
```

```bash,run
temporal workflow result -w campaign-summer-splash
```

Expected: `status` is `LIVE`, `channels_live` is 3, and the budget Activity
appears exactly once in Event History. Replay restores completed Activity
results; it does not repeat those side effects after the Worker restarts.

Confirm those events in the [button label="Temporal UI"](tab-5) tab, then
hit **Check**.

> [!NOTE]
> Stuck? Compare with `06-capstone/solution/` in the
> [button label="Editor"](tab-0) tab.
