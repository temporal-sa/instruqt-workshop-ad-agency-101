---
slug: activities
type: challenge
title: 3. Activities
teaser: Workflows orchestrate. Activities do the work.
notes:
- type: text
  contents: |-
    # Exercise 3: Activities
    move network I/O into an Activity and call it through a typed Workflow proxy.
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

**Goal:** move network I/O into an Activity and call it through a typed
Workflow proxy.

Workflow code must be deterministic and cannot call `fetch`. Activities
are ordinary async TypeScript functions and may perform network, file, or
database I/O. The Workflow imports only their types:

```ts
import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const { fetchHashtags } = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 seconds',
});
```

The `import type` is important: it keeps Node.js Activity implementation
code out of the Workflow sandbox.

# Step 1: Trace the worked Activity

In the [button label="Editor"](tab-0) tab, open
`03-activities/practice/`:

- `activities.ts` contains the worked `generateTagline` Activity.
- `workflows.ts` includes `generateTagline` in a typed Activity proxy and
  awaits it.
- `worker.ts` registers `generateTagline` with the Worker.

That is the complete path: Activity function → typed Workflow proxy →
Worker registration.

# Step 2: Implement `fetchHashtags`

In `activities.ts`, export an async `fetchHashtags(channel)` Activity. Fetch
`/trending/<channel>` and return the decoded hashtag list:

```ts
export async function fetchHashtags(channel: string): Promise<string[]> {
  const body = await getJson(`/trending/${channel}`);
  return body.hashtags as string[];
}
```

# Step 3: Call the Activity from the Workflow

In `workflows.ts`, add `fetchHashtags` to the existing typed proxy:

```ts
const { generateTagline, fetchHashtags } =
  proxyActivities<typeof activities>({
    startToCloseTimeout: '10 seconds',
  });
```

Then replace the empty hashtag list inside `socialPostWorkflow` with:

```ts
const hashtags = await fetchHashtags(channel);
```

The proxy schedules an Activity Task; it does not call the networked
implementation inside the Workflow sandbox.

# Step 4: Register the Activity

In `worker.ts`, import and register both Activity implementations:

```ts
import * as activities from './activities';

// Inside Worker.create:
activities,
```

# Step 5: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
npx tsx exercises/03-activities/practice/worker.ts
```

# Step 6: Start the Workflow

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type socialPostWorkflow \
  --task-queue social-tasks \
  --workflow-id social-post-1 \
  --input '"catstagram"'
```

```bash,run
temporal workflow result -w social-post-1
```

Expected output contains `CatNip Cola: Taste the Meow!`,
`#CatsOfCatstagram`, and `#SummerSplash`.

If an Activity is proxied but not registered, the Activity remains pending
and the Worker reports that the Activity type is not registered. Registration
is the link between an Activity Task on a queue and its implementation.

Open `social-post-1` in the [button label="Temporal UI"](tab-5) tab and find
both completed Activities in Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `03-activities/solution/` in the
> [button label="Editor"](tab-0) tab.
