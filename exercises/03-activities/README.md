# Exercise 3: Activities

**Goal:** move fallible work into activities, call them from a workflow with
timeouts, and assemble CatNip Cola's social post from two AdNet API calls.

## Concepts

**Why activities exist.** Workflow code must be deterministic — it gets
re-executed during recovery, so it can't talk to the network, read the clock,
or do anything that might come out differently twice. But real work *is*
network calls. The split: **workflows orchestrate, activities do the work.**
An activity is a plain Python function with `@activity.defn` on it. It can
fail, time out, and be retried — Temporal manages all of that, and your
workflow just awaits the result. If the workflow is replayed later, completed
activities are **not** re-executed; their recorded results are replayed from
history.

**The sandbox: determinism, enforced.** "Workflow code must be
deterministic" isn't an honor system in the Python SDK — it's enforced at
runtime. Workflow code runs inside a **sandbox**: for each workflow run, the
SDK re-imports your workflow file into an isolated environment (so no global
state leaks between runs), and known non-deterministic calls — `random`,
`time.time()`, `datetime.now()`, `os.urandom`, and friends — are patched to
raise a `RestrictedWorkflowAccessError` the moment workflow code touches
them. That's a feature: you find the determinism bug at your desk today, not
in a replay failure during an incident six months from now. When workflow
logic genuinely needs these, the SDK provides deterministic equivalents
(`workflow.now()`, `workflow.random()`, `workflow.uuid4()`, and
`asyncio.sleep()` becomes a durable server-side timer).

**Why the import looks weird.** That sandbox is why activity imports go
through this block in `workflows.py`:

```python
with workflow.unsafe.imports_passed_through():
    from activities import fetch_hashtags, generate_tagline
```

"Passed through" means: import this module **once, outside the sandbox**,
and hand the workflow a shared reference instead of re-importing it
per-run. Two reasons that's right for activities. First, correctness-wise
it's safe: the workflow never *calls* `fetch_hashtags` — it only uses the
reference to tell the server *which* activity to schedule; the actual
execution happens later, on a worker, outside the sandbox, where `requests`
and every other non-deterministic thing is fair game. Second, performance:
`activities.py` drags in `requests` and its whole dependency tree — without
passthrough the sandbox would re-import all of that for every single
workflow run. The `unsafe` in the name is the SDK making you say "I
understand this skips the sandbox's protection for these imports" — which
is exactly what you want for activity references, and exactly what you
*don't* want for, say, sneaking `import random` into workflow logic.

**Calling one — and what the arguments mean.** From workflow code:

```python
greeting = await workflow.execute_activity(
    greet,        # WHICH activity to schedule (the function reference)
    name,         # its INPUT — this value arrives as greet(name) on the worker
    start_to_close_timeout=timedelta(seconds=10),
)
```

The second positional value is the activity's argument: it's serialized,
shipped through the server, and handed to the function when a worker picks
the task up. (Activities with several parameters take `args=[a, b]` instead
— you'll use that in the capstone.) Because the input travels by *position*,
not by name, nothing stops you from passing the wrong variable — so read the
activity's signature and match it deliberately. In this exercise:
`generate_tagline(brand)` wants the **brand**, your `fetch_hashtags(channel)`
wants the **channel**. Cross them and you'll meet this in Pending
Activities, retrying forever:

```nocopy
404 Client Error: NOT FOUND for url: http://localhost:9999/trending/CatNip%20Cola
```

— the brand, sent where a channel belongs. (Why forever? A 404 raises a
plain `HTTPError`, which is retryable by default. Exercise 4 is entirely
about teaching Temporal which failures deserve that.)

`start_to_close_timeout` is how long a *single attempt* may run, and you must
always set it. Rule of thumb: comfortably longer than the operation's normal
duration (note the worked example's `requests` call has its own 5s timeout —
the inner timeout fails fast, the outer one is Temporal's enforcement).

**Registration: how an activity call actually lands.** `execute_activity`
doesn't call your function — it asks the server to put an *activity task*
on a task queue. Whichever worker polls that queue **and has that activity
registered** picks it up and runs it. Registration is the worker's
declaration of capability: the `activities=[...]` list in the `Worker(...)`
constructor is it saying "I can run these." (Plus an `activity_executor` —
a thread pool — because our activities are plain `def` functions making
blocking `requests` calls.)

Forgetting to register is a failure mode worth seeing once: the workflow
doesn't crash. The activity task gets picked up by your worker, which
reports *"Activity function fetch_hashtags is not registered on this
worker"* — and Temporal treats that as a failed attempt and retries,
forever, in case a properly-equipped worker shows up. In the UI it looks
like an activity stuck in **Pending Activities** with that message as the
last failure. Now you know what that means.

**One task queue or many?** In this workshop, one worker registers
everything on one queue per exercise — the right call for most apps
starting out. But the queue is a *routing* mechanism, and you can point any
single activity elsewhere:

```python
await workflow.execute_activity(
    render_video, scene,
    task_queue="gpu-tasks",   # different queue than the workflow's
    start_to_close_timeout=timedelta(minutes=5),
)
```

Why teams split activities across queues: **special hardware** (GPU
inference runs on the GPU boxes, API calls don't need them); **rate
limiting** (put the fragile third-party API's activities on their own queue
and cap that worker pool's concurrency); **independent scaling** (the
render-farm queue scales to fifty workers on demand while everything else
stays at three); and **isolation or ownership** (only workers inside the
payments subnet register the payment activities, deployed by the payments
team on their own cadence). One rule when you do this: every worker polling
a given queue must register the *same* set of workflows and activities —
the server assumes any poller can take any task on that queue.

## Part A: Read the worked example

Open `exercises/03-activities/practice/`. In `activities.py`,
`generate_tagline` is complete: decorator, AdNet call, timeout, return value.
In `workflows.py`, `SocialPostWorkflow` already executes it. Trace the path:
workflow → `execute_activity` → activity function → AdNet → back.

## Part B: Write `fetch_hashtags`

In `practice/activities.py`, follow the TODO: write an activity that takes a
channel name and returns its trending hashtags from
`GET http://localhost:9999/trending/<channel>`. Model it on
`generate_tagline`.

## Part C: Call it from the workflow

In `practice/workflows.py`, import `fetch_hashtags` (inside the
`imports_passed_through()` block — see Concepts above for why that block
exists) and replace the empty `hashtags` list with an `execute_activity`
call — passing `channel`, the run method's parameter, as its input. Watch
the variables: `BRAND` goes to `generate_tagline`, `channel` goes to
`fetch_hashtags`. If your workflow gets stuck retrying a `404 ...
/trending/...` with the brand in the URL, you've crossed them.

## Part D: Register it

In `practice/worker.py`, import `fetch_hashtags` and add it to the
`activities=[...]` list.

## Part E: Run it

Start (or **restart** — workers run the code they loaded at startup) your
worker:

```bash
uv run exercises/03-activities/practice/worker.py
```

Then in another terminal:

```bash
temporal workflow start \
  --type SocialPostWorkflow \
  --task-queue social-tasks \
  --workflow-id social-post-1 \
  --input '"catstagram"'
temporal workflow result -w social-post-1
```

Expected:

```
"CatNip Cola: Taste the Meow! #CatsOfCatstagram #SummerSplash"
```

In the Web UI, open `social-post-1` and find **both** activities in the event
history: `ActivityTaskScheduled` → `Started` → `Completed`, twice. Click a
`Completed` event to see the activity's recorded result — this is the value
that would be replayed instead of re-calling AdNet.

## Verify your work

```bash
temporal workflow describe -w social-post-1 -o json | jq -r '.workflowExecutionInfo.status'
# WORKFLOW_EXECUTION_STATUS_COMPLETED
temporal workflow result -w social-post-1
# contains hashtags
```

## Stretch (if you have time)

Fetch trending hashtags for `pettok` as well and append them to the post.
(Two `execute_activity` calls, or — preview of the capstone stretch — run
them in parallel with `asyncio.gather`.)

---

*Stuck or want to compare? See the `solution/` directory.*
