# Exercise 6: Capstone — make the campaign durable

**Goal:** rebuild the fragile exercise-1 launcher as a Temporal Workflow,
then kill its Worker during a retry.

The .NET mapping is:

| Before | Temporal |
|---|---|
| local async method | `[Activity]` method on `CampaignActivities` |
| direct method call | `Workflow.ExecuteActivityAsync` with a typed lambda |
| `foreach` loop | deterministic Workflow orchestration |
| thrown HTTP exception | retryable exception or non-retryable `ApplicationFailureException` |

# Step 1: Build the durable application

Use the [button label="Editor"](tab-0) tab, in `06-capstone/practice/`:

1. In `CampaignActivities.cs`, mark the four methods with `[Activity]`.
2. In `CampaignWorkflow.workflow.cs`, call each Activity with
   `Workflow.ExecuteActivityAsync` and a ten-second `StartToCloseTimeout`.
   Give `PublishToChannelAsync` this retry policy:

```csharp
RetryPolicy = new RetryPolicy
{
    InitialInterval = TimeSpan.FromSeconds(1),
    BackoffCoefficient = 2,
    MaximumInterval = TimeSpan.FromSeconds(10),
    NonRetryableErrorTypes = ["ChannelPolicyError"],
},
```

3. Rebuild the original sequence by awaiting `ValidateCreativeAsync`,
   `ReserveBudgetAsync`, each channel publication in order, and
   `GenerateLaunchReportAsync`.
4. In `PublishToChannelAsync`, convert 4xx responses to a non-retryable
   `ApplicationFailureException` with `errorType: "ChannelPolicyError"`.
5. In `Program.cs`, register the Activities with
   `.AddAllActivities(new CampaignActivities())`.

# Step 2: Launch through the outage

In the [button label="CLI"](tab-4) tab, turn chaos on:

```bash,run
curl -X POST localhost:9999/chaos/on
```

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
dotnet run --project exercises/06-capstone/practice/CampaignWorker.csproj
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
dotnet run --project exercises/06-capstone/practice/CampaignWorker.csproj
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
