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

The Java mapping is:

| Before | Temporal |
|---|---|
| ordinary method | method on an `@ActivityInterface` |
| direct method call | typed Activity stub call |
| local loop | deterministic Workflow orchestration |
| HTTP exception | retryable or non-retryable `ApplicationFailure` |

1. Add `@ActivityInterface` to `CampaignActivities`.
2. In `CampaignWorkflowImpl`, create ten-second Activity stubs. Give the
   publishing stub `RetryOptions` with:

```java
.setInitialInterval(Duration.ofSeconds(1))
.setBackoffCoefficient(2)
.setMaximumInterval(Duration.ofSeconds(10))
.setDoNotRetry("ChannelPolicyError")
```

3. Call, in order, `validateCreative`, `reserveBudget`,
   `publishToChannel` for all three channels, and `generateLaunchReport`.
4. Convert 4xx responses in `publishToChannel` to a non-retryable
   `ApplicationFailure` of type `ChannelPolicyError`.
5. Register `CampaignWorkflowImpl.class` and
   `new CampaignActivitiesImpl()` in `CampaignWorker`.

Start chaos, the Worker, and the Workflow:

```bash
curl -X POST localhost:9999/chaos/on
mvn -q -f exercises/06-capstone/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.CampaignWorker

temporal workflow start \
  --type CampaignWorkflow \
  --task-queue campaign-tasks \
  --workflow-id campaign-summer-splash \
  --input '"summer-splash"'
```

When PetTok is retrying, Ctrl-C the Worker. The Workflow stays Running.
Restart the Worker, turn chaos off, and fetch the result:

```bash
curl -X POST localhost:9999/chaos/off
temporal workflow result -w campaign-summer-splash
```

Expected: `status` is `LIVE` and `channels_live` is 3. The budget Activity
was scheduled exactly once because replay restores completed Activity
results instead of repeating their side effects.
