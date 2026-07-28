# Exercise 5: Human in the loop

**Goal:** pause a Workflow for an external approval, with a durable deadline.

A Signal changes state in a running Workflow:

```ts
export const approve = defineSignal<[approver: string]>('approve');

setHandler(approve, (approver) => {
  approvedBy = approver;
});
```

`condition(predicate, timeout)` waits without holding a Node.js thread. The
timeout is recorded as a Temporal timer, so both the wait and the deadline
survive Worker restarts.

1. In `practice/workflows.ts`, store the approver in the Signal handler.
2. Replace the placeholder with:

```ts
const received = await condition(
  () => approvedBy !== undefined,
  approvalDeadlineSeconds * 1_000,
);
```

3. Start the Worker:

```bash
npx tsx exercises/05-human-in-the-loop/practice/worker.ts
```

Start a run with a generous deadline, then Signal it:

```bash
temporal workflow start \
  --type campaignApprovalWorkflow \
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

Start `approval-2` with a five-second deadline and do not Signal it. The
first result must be `APPROVED`; the second must be `EXPIRED`. Inspect
`approval-2` in the UI to find its `TimerStarted` and `TimerFired` events.
