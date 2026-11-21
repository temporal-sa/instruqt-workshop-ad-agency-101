# Exercise 5: Human in the loop

**Goal:** pause a Workflow for an external approval, with a durable deadline.

A Signal changes state in a running Workflow. In Rust, a `#[signal]`
method mutates the Workflow struct:

```rust
#[signal]
pub fn approve(&mut self, _ctx: &mut SyncWorkflowContext<Self>, approver: String) {
    self.approved_by = Some(approver);
}
```

`ctx.wait_condition` waits for that state change without blocking a thread,
and `ctx.timer` starts a Temporal timer. Racing the two with the SDK's
deterministic `select!` gives a wait with a deadline. Both the wait and the
deadline survive Worker restarts.

# Step 1: Complete the Workflow

In the [button label="Editor"](tab-0) tab:

1. In `practice/workflows.rs`, store the approver in the `approve` Signal
   handler.
2. Replace the `let received = false;` placeholder with:

```rust
let received = select! {
    result = ctx.wait_condition(|state| state.approved_by.is_some()) => {
        result?;
        true
    }
    _ = ctx.timer(Duration::from_secs(approval_deadline_seconds)) => false,
};
```

The Workflow takes two inputs, the campaign and the deadline in seconds.
`MultiArgs2<String, u64>` receives them as two separate `--input` values.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
cargo run -q --bin approval-worker
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
