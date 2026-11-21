# Exercise 5: Human in the loop

**Goal:** pause a Workflow for an external approval, with a durable deadline.

A Signal changes state in a running Workflow. In PHP, a Signal handler is a
`#[SignalMethod]` on the Workflow class; the Signal name defaults to the
method name:

```php
#[SignalMethod]
public function approve(string $approver): void
{
    $this->approvedBy = $approver;
}
```

`Workflow::awaitWithTimeout()` waits without blocking the PHP process. It
resolves to `true` when the condition becomes true and to `false` when the
timeout fires. The timeout is recorded as a Temporal timer, so both the wait
and the deadline survive Worker restarts.

# Step 1: Complete the Workflow

In the [button label="Editor"](tab-0) tab, open
`05-human-in-the-loop/practice/CampaignApprovalWorkflow.php`:

1. In `approve`, store the approver in `$this->approvedBy`.
2. In `run`, replace the placeholder with:

```php
$received = yield Workflow::awaitWithTimeout(
    $approvalDeadlineSeconds,
    fn(): bool => $this->approvedBy !== null,
);
```

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
rr serve -o server.command="php exercises/05-human-in-the-loop/practice/worker.php"
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
