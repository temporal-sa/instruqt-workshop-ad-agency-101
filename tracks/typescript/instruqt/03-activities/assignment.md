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

1. In `practice/activities.ts`, export `fetchHashtags(channel)`. GET
   `http://localhost:9999/trending/<channel>` and return `body.hashtags`.
2. In `practice/workflows.ts`, include `fetchHashtags` in the typed proxy
   and await it for the requested channel.
3. In `practice/worker.ts`, import and register `fetchHashtags`.
4. Restart the Worker after editing:

```bash
npx tsx exercises/03-activities/practice/worker.ts
```

Then start the Workflow:

```bash
temporal workflow start \
  --type socialPostWorkflow \
  --task-queue social-tasks \
  --workflow-id social-post-1 \
  --input '"catstagram"'
temporal workflow result -w social-post-1
```

Expected output contains `CatNip Cola: Taste the Meow!`,
`#CatsOfCatstagram`, and `#SummerSplash`.

If an Activity is proxied but not registered, the Activity remains pending
and the Worker reports that the Activity type is not registered. Registration
is the link between an Activity Task on a queue and its implementation.
