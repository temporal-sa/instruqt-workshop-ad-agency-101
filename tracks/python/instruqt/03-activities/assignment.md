---
slug: activities
id: t41yyrxkkcio
type: challenge
title: 3. Activities
teaser: Workflows orchestrate. Activities do the work.
notes:
- type: text
  contents: "# Concepts for this challenge\nWorkflow code gets re-executed during
    recovery, so it must be\n**deterministic** — no network, no clocks, no dice. \U0001F3B2\U0001F6AB\n\nBut
    real work *is* network calls. The split:\n**workflows orchestrate, activities
    do the work.**"
- type: text
  contents: |-
    # Activities in one slide
    - A plain function + `@activity.defn`
    - Called with `await workflow.execute_activity(greet, name, start_to_close_timeout=...)`
      — the second value is the activity's **input**: it runs as `greet(name)`
      on a worker (several parameters: `args=[a, b]`)
    - Inputs travel by position, not by name — match the activity's signature
      deliberately
    - Can fail, time out, retry — Temporal manages all of it
    - Completed activities are **never re-executed** on replay; their recorded
      results are read back from history
    - Must be registered with the Worker (`activities=[...]`)
- type: text
  contents: |-
    # Determinism is enforced, not requested
    The Python SDK runs workflow code in a **sandbox**: your workflow file is
    re-imported per run in isolation, and non-deterministic calls (`random`,
    `time.time()`, `datetime.now()`...) raise `RestrictedWorkflowAccessError`
    on the spot. Bugs surface at your desk, not in a 2am replay.

    Need those things? Use the deterministic twins: `workflow.now()`,
    `workflow.random()`, `workflow.uuid4()` — and `asyncio.sleep()` becomes a
    durable server-side timer.

    `with workflow.unsafe.imports_passed_through():` imports a module **once,
    outside the sandbox** — right for activities, because the workflow only
    holds a *reference* to schedule them (they execute later, on a worker),
    and it spares the sandbox re-importing `requests` on every run.
- type: text
  contents: |-
    # Registration & task queues
    `execute_activity` never calls your function — it schedules an **activity
    task** on a task queue. A worker that polls the queue **and registered
    that activity** runs it. Forget to register one? The workflow doesn't
    crash: attempts fail with *"not registered on this worker"* and retry —
    look under **Pending Activities**.

    One queue fits most apps, but activities can be routed elsewhere with
    `execute_activity(..., task_queue="gpu-tasks")`. Teams split queues for
    special hardware, rate-limiting a fragile dependency, scaling heavy work
    independently, or isolation/ownership. Rule: all workers on one queue
    must register the same set.
tabs:
- id: rwlxd7ymbp5k
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: j9n3vyntfmuj
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: r6s2pf3a70dl
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: ntvobc5kuxyr
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: qt2vvky5elu6
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: dszekeakry9q
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: yul2zveak2d2
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: basic
timelimit: 900
enhanced_loading: null
---

Marketing wants a social post: the tagline plus whatever's trending on the
channel. Both come from AdNet — so both belong in **activities**.

# Step 1: Read the worked example

In the [button label="Editor"](tab-0) tab, open `03-activities/practice/activities.py`.
`generate_tagline` is complete: decorator, AdNet call, timeout, return.
Then open `03-activities/practice/workflows.py` and trace how `SocialPostWorkflow` executes it:
workflow → `execute_activity` → activity → AdNet → back.

# Step 2: Write `fetch_hashtags`

Follow the TODO in `03-activities/practice/activities.py`: an activity that takes a
channel name and returns its trending hashtags from
`GET http://localhost:9999/trending/<channel>`. Model it on
`generate_tagline`. Don't forget the decorator.

# Step 3: Call it from the workflow

In `03-activities/practice/workflows.py`: import `fetch_hashtags` inside the
`imports_passed_through()` block, then replace the empty `hashtags` list
with an `execute_activity` call — with a `start_to_close_timeout`, like the
example above it.

> [!IMPORTANT]
> The value you pass after the function reference is the activity's
> **input**. Match it to the signature: `generate_tagline(brand)` gets
> `BRAND`; your `fetch_hashtags(channel)` gets `channel`. Cross them and
> the workflow gets stuck retrying a
> `404 ... /trending/CatNip%20Cola` under **Pending Activities** —
> the brand, sent where a channel belongs.

Why the import block? The SDK's sandbox enforces determinism in workflow
code at runtime (try `import random` and using it in a workflow some time —
it'll be stopped on the spot). Passthrough imports happen once, *outside*
the sandbox: safe for activities because the workflow only holds a
reference to schedule them — the function itself runs later, on a worker.
The note slides for this challenge have the full story.

# Step 4: Register it

In `03-activities/practice/worker.py`, import `fetch_hashtags` and add it to
`activities=[...]`. This list is the worker declaring what it's capable of
running — `execute_activity` schedules a task on the queue, and only a
worker that registered that activity will execute it. (Skip this step and
watch what happens: the workflow doesn't crash; the activity retries with
*"not registered on this worker"* under **Pending Activities**.)

# Step 5: Run it

In the [button label="Worker"](tab-3) tab (Ctrl-C the old worker first if one is running):

```bash,run
uv run exercises/03-activities/practice/worker.py
```

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type SocialPostWorkflow \
  --task-queue social-tasks \
  --workflow-id social-post-1 \
  --input '"catstagram"'
```

```bash,run
temporal workflow result -w social-post-1
```

Expected:

```nocopy
"CatNip Cola: Taste the Meow! #CatsOfCatstagram #SummerSplash"
```

In the [button label="Temporal UI"](tab-5), open `social-post-1` and find
**both** activities in the history: `ActivityTaskScheduled` → `Started` →
`Completed`, twice. Click a `Completed` event to see the recorded result —
the value replay would use instead of re-calling AdNet.

When `social-post-1` has completed with hashtags in it, hit **Check**.

# Stretch (if you have time)

Fetch `pettok`'s trending hashtags too and append them to the post.

> [!NOTE]
> Stuck? Compare with `03-activities/solution/` in the [button label="Editor"](tab-0) tab.
