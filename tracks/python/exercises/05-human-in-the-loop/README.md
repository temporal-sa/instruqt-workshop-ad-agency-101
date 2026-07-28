# Exercise 5: Human in the loop

**Goal:** put a person inside a workflow. The client must approve Summer
Splash before it launches — approvals arrive as **signals**, the deadline is
a **durable timer**, and the expiry causes the code to **branch**.

## Concepts

**Signals.** A signal is a durable message sent to a *running* workflow —
from the CLI, another service, or a "click Approve" button in a web app. In
the workflow it's a decorated method that updates state:

```python
@workflow.signal
def approve(self, approver: str) -> None:
    self.approved_by = approver
```

Signals are recorded in the event history like everything else — which has a
delightful consequence you'll meet in the stretch.

**Waiting, durably.** `workflow.wait_condition(lambda: <state>, timeout=...)`
parks the workflow until the lambda turns true. Not polling, not holding a
thread — *parked*, for minutes or months, surviving worker restarts.

**Durable timers.** The `timeout` is a timer that lives on the **server**,
not in your process. When it fires first, `wait_condition` raises
`asyncio.TimeoutError`, and your code branches:

```python
try:
    await workflow.wait_condition(lambda: self.approved_by is not None,
                                  timeout=timedelta(seconds=deadline))
except asyncio.TimeoutError:
    ...   # the expiry branch
...       # the approved branch
```

This try/except is the whole human-in-the-loop pattern: wait for a person,
with a deadline, and decide what happens when the person doesn't show.

## Part A: Read the code

Open `exercises/05-human-in-the-loop/practice/workflows.py`.
`CampaignApprovalWorkflow` holds `approved_by` state, has an `approve`
signal handler, and a run method with both branches written — only the
waiting is missing.

## Part B: Finish the signal handler

Follow the TODO: record the approver's name on `self`.

## Part C: Wait with a deadline

Follow the TODO: `wait_condition` on "an approval has arrived", with
`timeout=timedelta(seconds=approval_deadline_seconds)`.

## Part D: The approved branch

Start your worker:

```bash
uv run exercises/05-human-in-the-loop/practice/worker.py
```

Start an approval with a 5-minute deadline (two `--input` flags — one per
workflow argument):

```bash
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-1 \
  --input '"summer-splash"' \
  --input '300'
```

In the Web UI, open `approval-1`: it's **Running**, and the event history
shows `TimerStarted` — that's your deadline, living on the server. Now be
the client (CatNip Cola's brand manager, Whiskers LeBlanc, is decisive):

```bash
temporal workflow signal -w approval-1 --name approve --input '"Whiskers LeBlanc"'
temporal workflow result -w approval-1
```

`"status": "APPROVED"`, `"approved_by": "Whiskers LeBlanc"` — and in the
history: `WorkflowExecutionSignaled`, then completion. The timer never got
its moment.

## Part E: The expiry branch

This time, nobody approves. Use a deadline short enough to watch:

```bash
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-2 \
  --input '"summer-splash"' \
  --input '30'
temporal workflow result -w approval-2
```

Thirty seconds later: `"status": "EXPIRED"`. In the history: `TimerStarted`
→ `TimerFired` → the *other* branch ran. Same code, two recorded fates —
compare `approval-1` and `approval-2` side by side in the UI.

## Verify your work

```bash
# approval-1: APPROVED via signal
temporal workflow show -w approval-1 -o json | \
  jq '[.events[] | select(.workflowExecutionSignaledEventAttributes != null)] | length'   # >= 1

# approval-2: EXPIRED via durable timer
temporal workflow show -w approval-2 -o json | \
  jq '[.events[] | select(.timerFiredEventAttributes != null)] | length'   # >= 1
```

## Stretch: signal a workflow that has no worker

The deadline isn't the only thing that's durable. **Stop your worker**
(Ctrl-C), then:

```bash
temporal workflow start \
  --type CampaignApprovalWorkflow \
  --task-queue approval-tasks \
  --workflow-id approval-3 \
  --input '"summer-splash"' \
  --input '300'
temporal workflow signal -w approval-3 --name approve --input '"Whiskers LeBlanc"'
```

Both succeed — you just started *and approved* a workflow while **zero
lines of your code were running anywhere**. The signal is queued in the
history. Start your worker and check the result: instantly `APPROVED`. The
approval survived a world with no compute in it. That's what "durable"
means.

---

*Stuck or want to compare? See the `solution/` directory.*
