# Exercise 6: Capstone — make the campaign durable

**Goal:** rebuild the fragile exercise-1 launcher as a Temporal Workflow,
then kill its Worker during a retry.

The TypeScript mapping is:

| Before | Temporal |
|---|---|
| local async function | exported async Activity implementation |
| direct function call | typed Activity proxy call |
| `for` loop | deterministic Workflow orchestration |
| thrown HTTP error | retryable or non-retryable `ApplicationFailure` |

# Step 1: Build the durable application

Use the [button label="Editor"](tab-0) tab:

1. In `practice/activities.ts`, export the four Activity functions.
2. In `practice/workflows.ts`, create Activity proxies with ten-second
   start-to-close timeouts. Give `publishToChannel` this retry policy:

```ts
retry: {
  initialInterval: '1 second',
  backoffCoefficient: 2,
  maximumInterval: '10 seconds',
  nonRetryableErrorTypes: ['ChannelPolicyError'],
}
```

3. Rebuild the original sequence by awaiting `validateCreative`,
   `reserveBudget`, each channel publication in order, and
   `generateLaunchReport`.
4. In `publishToChannel`, convert 4xx responses to a non-retryable
   `ApplicationFailure` of type `ChannelPolicyError`.
5. In `practice/worker.ts`, replace the empty Activity object with the
   imported `activities` namespace.

# Step 2: Launch through the outage

In the [button label="CLI"](tab-4) tab, turn chaos on:

```bash,run
curl -X POST localhost:9999/chaos/on
```

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
npx tsx exercises/06-capstone/practice/worker.ts
```

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type campaignWorkflow \
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
npx tsx exercises/06-capstone/practice/worker.ts
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
