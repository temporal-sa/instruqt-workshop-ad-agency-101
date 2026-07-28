---
slug: human-in-the-loop
type: challenge
title: 5. Human in the loop
teaser: The client must approve. Approvals expire. Signals, durable timers, branching.
notes:
- type: text
  contents: |-
    # Exercise 5: Human in the loop
    pause a Workflow for external approval, with a durable deadline.
tabs:
- id: otrkk0qs7rex
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: lakxh2ngkchc
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: pg0ft0rnyxzh
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: fizgkcpybp0a
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: d8qoaczkytqf
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: ol9gxa66xh6y
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: yiqgunawfdnx
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: intermediate
timelimit: 1200
enhanced_loading: null
---

# Exercise 5: Human in the loop

**Goal:** pause a Workflow for external approval, with a durable deadline.

Signals update state in a running Workflow:

```java
@SignalMethod
void approve(String approver);
```

`Workflow.await(Duration, predicate)` waits without holding an operating
system thread. Its timeout is a durable Temporal timer, so both the wait and
deadline survive Worker restarts.

1. Store the approver in `CampaignApprovalWorkflowImpl.approve`.
2. Wait in `awaitApproval`:

```java
boolean received =
    Workflow.await(
        Duration.ofSeconds(approvalDeadlineSeconds),
        () -> approvedBy != null);
```

3. Start the Worker:

```bash
mvn -q -f exercises/05-human-in-the-loop/practice/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.ApprovalWorker
```

Start and Signal an approval:

```bash
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-1 \
  --input '"summer-splash"' \
  --input '120'

temporal workflow signal \
  --workflow-id approval-1 \
  --name approve \
  --input '"Whiskers LeBlanc"'
temporal workflow result -w approval-1
```

Run `approval-2` with a five-second deadline and do not Signal it. The first
run must report `APPROVED`; the second must report `EXPIRED`.
