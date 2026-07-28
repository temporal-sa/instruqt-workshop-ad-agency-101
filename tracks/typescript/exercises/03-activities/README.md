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

# Step 1: Complete and register the Activity

In the [button label="Editor"](tab-0) tab:

1. In `practice/activities.ts`, export `fetchHashtags(channel)`. GET
   `http://localhost:9999/trending/<channel>` and return `body.hashtags`.
2. In `practice/workflows.ts`, include `fetchHashtags` in the typed proxy
   and await it for the requested channel.
3. In `practice/worker.ts`, import and register `fetchHashtags`.

# Step 2: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
npx tsx exercises/03-activities/practice/worker.ts
```

# Step 3: Start the Workflow

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
