# Exercise 6: Capstone — make the campaign durable

**Goal:** rebuild the fragile exercise-1 launcher as a Temporal Workflow,
then kill its Worker during a retry.

The Rust mapping is:

| Before | Temporal |
|---|---|
| local async function | `#[activity]` method on `CampaignActivities` |
| direct function call | `ctx.execute_activity(...)` |
| `for` loop | deterministic Workflow orchestration |
| returned HTTP error | retryable or non-retryable `ApplicationFailure` |

# Step 1: Build the durable application

Use the [button label="Editor"](tab-0) tab:

1. In `practice/activities.rs`, put `#[activities]` on the
   `impl CampaignActivities` block and `#[activity]` on each of the four
   methods.
2. In `practice/workflows.rs`, schedule every Activity with a ten-second
   start-to-close timeout. Give `publish_to_channel` this retry policy:

```rust
RetryPolicy::builder()
    .initial_interval(Duration::from_secs(1))
    .backoff_coefficient(2.0)
    .maximum_interval(Duration::from_secs(10))
    .non_retryable_error_types(["ChannelPolicyError"])
    .build()
```

3. Rebuild the original sequence by awaiting
   `CampaignActivities::validate_creative`, `reserve_budget`, each channel
   publication in order, and `generate_launch_report`. Pass multiple
   Activity arguments as a tuple, for example
   `(campaign.clone(), channel.to_string())`.
4. In `publish_to_channel`, convert 4xx responses to a non-retryable
   `ApplicationFailure` of type `ChannelPolicyError`.
5. In `practice/worker.rs`, register `CampaignActivities`.

# Step 2: Launch through the outage

In the [button label="CLI"](tab-4) tab, turn chaos on:

```bash,run
curl -X POST localhost:9999/chaos/on
```

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
cargo run -q --bin campaign-worker
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
cargo run -q --bin campaign-worker
```

Recover AdNet from the [button label="CLI"](tab-4) tab:

```bash,run
curl -X POST localhost:9999/chaos/off
```

```bash,run
temporal workflow result -w campaign-summer-splash
```

Expected: `status` is `LIVE`, `channels_live` is 3, and the
`CampaignActivities::reserve_budget` Activity appears exactly once in Event
History. Replay restores completed Activity results; it does not repeat
those side effects after the Worker restarts.

Confirm those events in the [button label="Temporal UI"](tab-5) tab, then
hit **Check**.

> [!NOTE]
> Stuck? Compare with `06-capstone/solution/` in the
> [button label="Editor"](tab-0) tab.
