---
slug: to-the-cloud
id: imnnxgw0glz6
type: challenge
title: '8. Take-home: to the cloud'
teaser: Point your worker at a real Temporal Cloud namespace. API key, TLS, zero code
  changes.
notes:
- type: text
  contents: "# One more thing \U0001F680\nAll workshop long, your workflows ran against
    a local dev server.\nProduction means a real Temporal Service — for most teams,
    **Temporal\nCloud**.\n\nThe punchline: connecting to it changes **one function
    call**. Same\nworkflows, same task queues, same CLI commands."
- type: text
  contents: |-
    # This one's homework
    It needs a Temporal Cloud account (free credits included with signup),
    so we won't run it during the workshop. Grab everything — including the
    cloud-ready worker — from the **Download** tab and run it on your laptop.
tabs:
- id: zbb8lj0dbzaf
  title: Editor
  type: code
  hostname: workstation
  path: /root/workshop/exercises
- id: xnxgydvx6j5u
  title: Server
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s server
- id: p28n4t7mrrvr
  title: AdNet
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s adnet
- id: ltrdabrcwcll
  title: Worker
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s worker
- id: 0cnwxobuloxt
  title: CLI
  type: terminal
  hostname: workstation
  workdir: /root/workshop
  cmd: tmux new-session -A -s cli
- id: inmna4igqihr
  title: Temporal UI
  type: service
  hostname: workstation
  port: 8233
- id: 9awcznhdpcfr
  title: Download
  type: service
  hostname: workstation
  port: 8000
  new_window: true
difficulty: intermediate
timelimit: 900
enhanced_loading: null
---

Your workflows have been running against `temporal server start-dev`. This
final exercise connects the same code to **Temporal Cloud** — a managed,
production-grade Temporal Service — authenticated with an **API key**.

It needs a Cloud account, so treat it as your take-home: read it now, run
it tonight. The [button label="Download"](tab-6) tab has the entire
workshop as a zip — every exercise, practice and solution, plus AdNet —
ready to run on your laptop with `uv` and the `temporal` CLI installed.
(If you already have a Cloud account and time to spare, it also works
right here in the sandbox.)

# Step 1: Get a namespace

1. Sign up / sign in at [cloud.temporal.io](https://cloud.temporal.io) —
   new accounts include free credits, more than enough for this.
2. Create a namespace (**Namespaces → Create Namespace**): pick a name and
   a region. The full namespace ID is `<name>.<account-id>` — copy it
   exactly as shown.

# Step 2: Create an API key

In **Settings → API Keys** (or your profile → API Keys), create a key with
a short expiry and access to your namespace. Copy the `tmprl_...` value
immediately — it's shown once.

API keys are bearer credentials: whoever holds the key acts as you. Treat
them like passwords.

# Step 3: Point your environment at the cloud

API-key auth uses Temporal Cloud's **regional gRPC endpoints**:
`<region>.<cloud-provider>.api.temporal.io:7233` — match the region from
Step 1. In the [button label="CLI"](tab-4) tab (or your laptop shell):

```bash
export TEMPORAL_ADDRESS="us-east-1.aws.api.temporal.io:7233"   # your region here
export TEMPORAL_NAMESPACE="<name>.<account-id>"                # from Step 1
export TEMPORAL_API_KEY="tmprl_..."                            # from Step 2
export TEMPORAL_TLS=true
```

The `temporal` CLI reads these variables, so it's now pointed at your Cloud
namespace. Verify before touching code:

```bash,run
temporal workflow list
```

An empty list with no error means you're in.

> [!NOTE]
> To return this shell to the local dev server afterwards:
> `unset TEMPORAL_ADDRESS TEMPORAL_NAMESPACE TEMPORAL_API_KEY TEMPORAL_TLS`

# Step 4: Run the cloud worker

Open `08-to-the-cloud/worker.py` in the [button label="Editor"](tab-0) tab
and compare it to exercise 2's worker. The diff is **one function call**:

```python
client = await Client.connect(
    os.environ["TEMPORAL_ADDRESS"],
    namespace=os.environ["TEMPORAL_NAMESPACE"],
    api_key=os.environ["TEMPORAL_API_KEY"],
    tls=True,
)
```

Export the same four variables in the [button label="Worker"](tab-3) tab,
then:

```bash
uv run exercises/08-to-the-cloud/worker.py
```

Your terminal is now a worker fleet (population: 1) for a production-grade
Temporal Service.

# Step 5: Run a workflow on Temporal Cloud

Back in the [button label="CLI"](tab-4) tab — the workshop's very first
workflow, unchanged:

```bash,run
temporal workflow start \
  --type TaglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id cloud-tagline-1 \
  --input '"CatNip Cola"'
```

```bash,run
temporal workflow result -w cloud-tagline-1
```

Open your namespace at [cloud.temporal.io](https://cloud.temporal.io):
there's `cloud-tagline-1`, with the same event history you learned to read
today — same events, same UI, running on the managed service.

# Where this goes next

- Production workers run exactly like this one — plain processes on your
  VMs, containers, or Kubernetes. Run at least two for availability.
- **mTLS** is the alternative auth for service-to-service setups; API keys
  are the fastest way in.
- Keep going: [docs.temporal.io/cloud](https://docs.temporal.io/cloud) and
  the free courses at [learn.temporal.io](https://learn.temporal.io).

That's the workshop, end to end: a fragile script, made durable, debugged
through its own history, gated on a human — and connected to the real
thing. Hit **Next** to finish. 🥤🐈
