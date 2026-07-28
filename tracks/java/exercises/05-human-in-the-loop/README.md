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
