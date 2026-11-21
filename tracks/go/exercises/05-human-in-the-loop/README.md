# Exercise 5: Human in the loop

**Goal:** pause a Workflow for an external approval, with a durable deadline.

In Go, Signals arrive on a Workflow channel. A Workflow goroutine started
with `workflow.Go` receives the Signal and updates Workflow state:

```go
approveCh := workflow.GetSignalChannel(ctx, "approve")
workflow.Go(ctx, func(ctx workflow.Context) {
	approveCh.Receive(ctx, &approvedBy)
})
```

`workflow.AwaitWithTimeout(ctx, timeout, condition)` waits without blocking
an operating system thread. The timeout is recorded as a Temporal timer, so
both the wait and the deadline survive Worker restarts.

# Step 1: Complete the Workflow

In the [button label="Editor"](tab-0) tab, open
`05-human-in-the-loop/practice/workflow.go`:

1. In the Signal goroutine, store the approver in `approvedBy`.
2. Replace the `received := false` placeholder with:

```go
received, err := workflow.AwaitWithTimeout(ctx,
	time.Duration(approvalDeadlineSeconds)*time.Second,
	func() bool { return approvedBy != "" })
if err != nil {
	return ApprovalReport{}, err
}
```

Add `"time"` to the imports.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
go run ./exercises/05-human-in-the-loop/practice/worker
```

# Step 3: Approve a running Workflow

In the [button label="CLI"](tab-4) tab, start a run with a generous
deadline:

```bash,run
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-1 \
  --input '"summer-splash"' \
  --input '120'
```

Open `approval-1` in the [button label="Temporal UI"](tab-5) tab. It remains
Running while its durable deadline timer waits. Return to the
[button label="CLI"](tab-4) tab and Signal it:

```bash,run
temporal workflow signal \
  --workflow-id approval-1 \
  --name approve \
  --input '"Whiskers LeBlanc"'
```

```bash,run
temporal workflow result -w approval-1
```

# Step 4: Let an approval expire

In the [button label="CLI"](tab-4) tab, start `approval-2` with a
five-second deadline and do not Signal it:

```bash,run
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-2 \
  --input '"summer-splash"' \
  --input '5'
```

```bash,run
temporal workflow result -w approval-2
```

The first result must be `APPROVED`; the second must be `EXPIRED`. Inspect
`approval-2` in the [button label="Temporal UI"](tab-5) tab to find its
`TimerStarted` and `TimerFired` events, then hit **Check**.

> [!NOTE]
> Stuck? Compare with `05-human-in-the-loop/solution/` in the
> [button label="Editor"](tab-0) tab.
