# Exercise 6: Capstone — make the campaign durable

**Goal:** rebuild the fragile exercise-1 launcher as a Temporal Workflow,
then kill its Worker during a retry.

The Go mapping is:

| Before | Temporal |
|---|---|
| plain function | exported Activity method on a struct |
| direct function call | `workflow.ExecuteActivity(...).Get(...)` |
| `for` loop | deterministic Workflow orchestration |
| returned HTTP error | retryable error or non-retryable `ApplicationError` |

# Step 1: Build the durable application

Use the [button label="Editor"](tab-0) tab and open
`06-capstone/practice/`:

1. In `activities.go`, export the four `CampaignActivities` methods by
   capitalizing them: `ValidateCreative`, `ReserveBudget`,
   `PublishToChannel`, and `GenerateLaunchReport`.
2. In `workflow.go`, derive Activity contexts with ten-second
   `StartToCloseTimeout`s. Give the publishing context this retry policy:

```go
RetryPolicy: &temporal.RetryPolicy{
	InitialInterval:        time.Second,
	BackoffCoefficient:     2,
	MaximumInterval:        10 * time.Second,
	NonRetryableErrorTypes: []string{"ChannelPolicyError"},
},
```

3. Rebuild the original sequence with `workflow.ExecuteActivity` and
   `.Get`: `ValidateCreative`, `ReserveBudget`, `PublishToChannel` for each
   channel in order, and `GenerateLaunchReport`.
4. In `PublishToChannel`, convert 4xx responses to a non-retryable
   `ApplicationError` of type `ChannelPolicyError`.
5. In `worker/main.go`, register `campaign.CampaignWorkflow` and
   `&campaign.CampaignActivities{}`.

# Step 2: Launch through the outage

In the [button label="CLI"](tab-4) tab, turn chaos on:

```bash,run
curl -X POST localhost:9999/chaos/on
```

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
go run ./exercises/06-capstone/practice/worker
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
go run ./exercises/06-capstone/practice/worker
```

Recover AdNet from the [button label="CLI"](tab-4) tab:

```bash,run
curl -X POST localhost:9999/chaos/off
```

```bash,run
temporal workflow result -w campaign-summer-splash
```

Expected: `status` is `LIVE`, `channels_live` is 3, and the `ReserveBudget`
Activity appears exactly once in Event History. Replay restores completed
Activity results; it does not repeat those side effects after the Worker
restarts.

Confirm those events in the [button label="Temporal UI"](tab-5) tab, then
hit **Check**.

> [!NOTE]
> Stuck? Compare with `06-capstone/solution/` in the
> [button label="Editor"](tab-0) tab.
