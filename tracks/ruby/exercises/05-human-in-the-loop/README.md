# Exercise 5: Human in the loop

**Goal:** pause a Workflow for an external approval, with a durable deadline.

A Signal changes state in a running Workflow. In Ruby, mark a method with
`workflow_signal`; the Signal name defaults to the method name:

```ruby
workflow_signal
def approve(approver)
  @approved_by = approver
end
```

`Temporalio::Workflow.wait_condition` waits on a fiber without holding a
thread. Wrapping it in `Temporalio::Workflow.timeout` records the deadline
as a Temporal timer, so both the wait and the deadline survive Worker
restarts. When the timer fires first, `timeout` raises `Timeout::Error`.

# Step 1: Complete the Workflow

In the [button label="Editor"](tab-0) tab:

1. In `practice/workflows.rb`, store the approver in `@approved_by` in the
   `approve` Signal handler.
2. Replace the `received = false` placeholder with:

```ruby
received = begin
  Temporalio::Workflow.timeout(approval_deadline_seconds) do
    Temporalio::Workflow.wait_condition { @approved_by }
  end
  true
rescue Timeout::Error
  false
end
```

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
bundle exec ruby exercises/05-human-in-the-loop/practice/worker.rb
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
