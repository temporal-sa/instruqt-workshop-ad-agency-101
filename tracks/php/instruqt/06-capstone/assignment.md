---
slug: capstone
type: challenge
title: '6. Capstone: make it durable'
teaser: The script from challenge 1, reborn. Kill the worker. Launch anyway.
notes:
- type: text
  contents: |-
    # Exercise 6: Capstone — make the campaign durable
    rebuild the fragile exercise-1 launcher as a Temporal Workflow, then kill its Worker during a retry.
tabs:
- id: pzqvdtzyu9he
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: jjyaspoa5kyr
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: byp58jtctszp
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: lhy8mxujblxl
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: it05tumri5y1
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: 2buuuf7xpzjg
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: sczkl3jubyn1
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: intermediate
timelimit: 1500
enhanced_loading: null
---

# Exercise 6: Capstone — make the campaign durable

**Goal:** rebuild the fragile exercise-1 launcher as a Temporal Workflow,
then kill its Worker during a retry.

The PHP mapping is:

| Before | Temporal |
|---|---|
| plain function | method on an `#[ActivityInterface]` implementation |
| direct function call | `yield` on a typed Activity stub call |
| `foreach` loop | deterministic Workflow orchestration |
| `RuntimeException` on HTTP errors | retryable failure, or non-retryable `ApplicationFailure` |

# Step 1: Build the durable application

Use the [button label="Editor"](tab-0) tab and open `06-capstone/practice/`:

1. In `CampaignActivityInterface.php`, add
   `#[ActivityInterface(prefix: 'Campaign.')]` above the interface.
2. In `CampaignWorkflow.php`, create two Activity stubs in a constructor,
   both with ten-second start-to-close timeouts. Give the publishing stub
   this retry policy:

```php
RetryOptions::new()
    ->withInitialInterval(1)
    ->withBackoffCoefficient(2)
    ->withMaximumInterval(10)
```

3. Rebuild the original sequence in `run` by yielding
   `validateCreative`, `reserveBudget`, `publishToChannel` for each channel
   in order, and `generateLaunchReport`.
4. In `CampaignActivity.php`, convert 4xx responses in `publishToChannel`
   to a non-retryable `ApplicationFailure` of type `ChannelPolicyError`.
   In PHP, the failure itself carries `nonRetryable: true`;
   `RetryOptions::withNonRetryableExceptions()` takes PHP exception class
   names, not failure types.
5. In `worker.php`, register `CampaignWorkflow::class` with
   `registerWorkflowTypes()` and `CampaignActivity::class` with
   `registerActivity()`.

# Step 2: Launch through the outage

In the [button label="CLI"](tab-4) tab, turn chaos on:

```bash,run
curl -X POST localhost:9999/chaos/on
```

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
rr serve -o server.command="php exercises/06-capstone/practice/worker.php"
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
rr serve -o server.command="php exercises/06-capstone/practice/worker.php"
```

Recover AdNet from the [button label="CLI"](tab-4) tab:

```bash,run
curl -X POST localhost:9999/chaos/off
```

```bash,run
temporal workflow result -w campaign-summer-splash
```

Expected: `status` is `LIVE`, `channels_live` is 3, and the
`Campaign.reserveBudget` Activity appears exactly once in Event History.
Replay restores completed Activity results; it does not repeat those side
effects after the Worker restarts.

Confirm those events in the [button label="Temporal UI"](tab-5) tab, then
hit **Check**.

> [!NOTE]
> Stuck? Compare with `06-capstone/solution/` in the
> [button label="Editor"](tab-0) tab.
