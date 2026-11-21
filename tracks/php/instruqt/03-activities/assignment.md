---
slug: activities
type: challenge
title: 3. Activities
teaser: Workflows orchestrate. Activities do the work.
notes:
- type: text
  contents: |-
    # Exercise 3: Activities
    move network I/O into an Activity and call it from a Workflow through a typed stub.
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

# Exercise 3: Activities

**Goal:** move network I/O into an Activity and call it from a Workflow
through a typed stub.

Workflow code must be deterministic. The PHP SDK has no Workflow sandbox, so
nothing stops a Workflow from calling `curl_exec()`: you must keep network,
file, database, clock, and random operations out of it yourself. Put side
effects in an `#[ActivityInterface]` implementation and create a stub:

```php
$this->hashtagActivities = Workflow::newActivityStub(
    HashtagActivityInterface::class,
    ActivityOptions::new()->withStartToCloseTimeout(10),
);
```

The Activity Type is the interface prefix plus the method name, for example
`Hashtag.fetchHashtags`.

# Step 1: Trace the worked Activity

In the [button label="Editor"](tab-0) tab, open
`03-activities/practice/`:

- `TaglineActivityInterface.php` defines the Activity contract.
- `TaglineActivity.php` performs the AdNet request.
- `SocialPostWorkflow.php` creates a typed `taglineActivities` stub and
  yields `generateTagline`.
- `worker.php` registers `TaglineActivity::class`.

That is the complete path: Activity interface → implementation → typed
Workflow stub → Worker registration.

# Step 2: Complete `fetchHashtags`

In `HashtagActivity.php`, finish `fetchHashtags`. Fetch
`/trending/<channel>` and return the decoded hashtag list:

```php
$body = AdNetClient::getJson("/trending/{$channel}");
return $body['hashtags'];
```

# Step 3: Call the Activity from the Workflow

Open `SocialPostWorkflow.php`. The `hashtagActivities` typed stub is
already created in the constructor. Inside `run`, replace the empty list:

```php
$hashtags = [];
```

with the Activity call:

```php
$hashtags = yield $this->hashtagActivities->fetchHashtags($channel);
```

This does not call `HashtagActivity` directly. The stub returns a promise
for a `Hashtag.fetchHashtags` Activity Task, and `yield` waits durably for
its result. Without `yield`, you would get the promise, not the hashtags.

# Step 4: Register the implementation

Open `worker.php` and register the new implementation next to the existing
one:

```php
$worker->registerActivity(TaglineActivity::class);
$worker->registerActivity(HashtagActivity::class);
```

The Workflow stub schedules the task; this registered implementation is
what lets the Worker execute it.

# Step 5: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
rr serve -o server.command="php exercises/03-activities/practice/worker.php"
```

# Step 6: Start the Workflow

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

Expected output contains `CatNip Cola: Taste the Meow!`,
`#CatsOfCatstagram`, and `#SummerSplash`.

If an Activity is called but not registered, the Activity keeps retrying,
and its last failure in Pending Activities reads `unable to find
activityType=Hashtag.fetchHashtags`. Registration is the link between an
Activity Task on a queue and its implementation.

Open `social-post-1` in the [button label="Temporal UI"](tab-5) tab and find
both completed Activities in Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `03-activities/solution/` in the
> [button label="Editor"](tab-0) tab.
