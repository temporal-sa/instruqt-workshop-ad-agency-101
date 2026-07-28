---
slug: human-in-the-loop
id: wx2jpvtxqlg6
type: challenge
title: 5. Human in the loop
teaser: The client must approve. Approvals expire. Signals, durable timers, branching.
notes:
- type: text
  contents: |-
    # Concepts for this challenge
    **Signals** — durable messages sent to a *running* workflow (from a CLI,
    a service, or an "Approve" button). In the workflow: a decorated method
    that updates state.

    **Durable timers** — deadlines that live on the **server**, not in your
    process. They fire on time even if no worker is running.
- type: text
  contents: |-
    # The human-in-the-loop pattern, in one try/except
    ```python
    try:
        await workflow.wait_condition(
            lambda: self.approved_by is not None,
            timeout=timedelta(seconds=deadline),
        )
    except asyncio.TimeoutError:
        ...   # expiry branch
    ...       # approved branch
    ```
    Wait for a person, with a deadline, and branch when they don't show.
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

Legal says the client must sign off on Summer Splash before a single ad
goes live — and approvals expire. Time to put a human inside a workflow.

# Step 1: Read the code

In the [button label="Editor"](tab-0) tab, open `05-human-in-the-loop/practice/workflows.py`.
`CampaignApprovalWorkflow` holds `approved_by` state, has an `approve`
signal handler, and both branches of the run method are written — only the
waiting is missing.

# Step 2: Finish the signal handler

Follow the TODO: record the approver's name on `self`.

# Step 3: Wait with a deadline

Follow the TODO: `workflow.wait_condition` on "an approval has arrived",
with `timeout=timedelta(seconds=approval_deadline_seconds)`.

# Step 4: The approved branch

In the [button label="Worker"](tab-3) tab (Ctrl-C any old worker):

```bash,run
uv run exercises/05-human-in-the-loop/practice/worker.py
```

In the [button label="CLI"](tab-4) tab, start an approval with a 5-minute deadline (two
`--input` flags — one per workflow argument):

```bash,run
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-1 \
  --input '"summer-splash"' \
  --input '300'
```

In the [button label="Temporal UI"](tab-5), open `approval-1`: it's
**Running**, and the history shows `TimerStarted` — your deadline, living
on the server. Now be the client (CatNip Cola's brand manager, Whiskers
LeBlanc, is decisive):

```bash,run
temporal workflow signal -w approval-1 --name approve --input '"Whiskers LeBlanc"'
```

```bash,run
temporal workflow result -w approval-1
```

`"status": "APPROVED"` — and the history shows `WorkflowExecutionSignaled`.
The timer never got its moment.

# Step 5: The expiry branch

This time nobody approves. Thirty-second deadline — watch it happen, from
the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-2 \
  --input '"summer-splash"' \
  --input '30'
```

```bash,run
temporal workflow result -w approval-2
```

`"status": "EXPIRED"`. In the history: `TimerStarted` → `TimerFired` → the
*other* branch ran. Compare `approval-1` and `approval-2` side by side in the
[button label="Temporal UI"](tab-5): same code, two recorded fates. Hit **Check**.

# Stretch: signal a workflow that has no worker

The deadline isn't the only durable thing here. **Stop your worker** in the
[button label="Worker"](tab-3) tab (Ctrl-C), then run both of these from the
[button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-3 \
  --input '"summer-splash"' \
  --input '300'
```

```bash,run
temporal workflow signal -w approval-3 --name approve --input '"Whiskers LeBlanc"'
```

Both succeed — you just started *and approved* a workflow while **zero
lines of your code were running anywhere**. Start the worker and check the
result: instantly `APPROVED`. That's what durable means.

> [!NOTE]
> Stuck? Compare with `05-human-in-the-loop/solution/` in the [button label="Editor"](tab-0) tab.
