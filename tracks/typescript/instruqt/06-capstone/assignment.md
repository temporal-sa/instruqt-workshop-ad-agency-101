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

The TypeScript mapping is:

| Before | Temporal |
|---|---|
| local async function | exported async Activity implementation |
| direct function call | typed Activity proxy call |
| `for` loop | deterministic Workflow orchestration |
| thrown HTTP error | retryable or non-retryable `ApplicationFailure` |

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

Start chaos, then the Worker and Workflow:

```bash
curl -X POST localhost:9999/chaos/on
npx tsx exercises/06-capstone/practice/worker.ts

temporal workflow start \
  --type campaignWorkflow \
  --task-queue campaign-tasks \
  --workflow-id campaign-summer-splash \
  --input '"summer-splash"'
```

Wait until PetTok is retrying, Ctrl-C the Worker, and inspect the execution:

```bash
temporal workflow describe -w campaign-summer-splash
```

It remains Running. Restart the Worker, recover AdNet, and get the result:

```bash
curl -X POST localhost:9999/chaos/off
temporal workflow result -w campaign-summer-splash
```

Expected: `status` is `LIVE`, `channels_live` is 3, and the budget Activity
appears exactly once in Event History. Replay restores completed Activity
results; it does not repeat those side effects after the Worker restarts.
