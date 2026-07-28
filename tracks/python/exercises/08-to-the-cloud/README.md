# Exercise 8 (take-home): To the cloud

**Goal:** connect the worker you've been running all workshop to a **Temporal
Cloud** namespace, authenticated with an API key — and prove that nothing
else about your code has to change.

All workshop long, your workflows ran against `temporal server start-dev` —
a single-binary dev server with no durability guarantees beyond its local
db file. Production means a real Temporal Service: most teams use
[Temporal Cloud](https://temporal.io/cloud), where namespaces, scaling, and
the control plane are managed for you and your code talks to it over TLS.

The punchline of this exercise: **the only thing that changes is
`Client.connect()`**. Same workflow definitions. Same task queues. Same CLI
commands. Compare [worker.py](worker.py) with exercise 2's worker — the diff
is one function call.

> This one needs a Temporal Cloud account, so it's homework rather than
> workshop time. New accounts come with free credits — more than enough for
> this exercise.

## Part A: Get a namespace

1. Sign up / sign in at [cloud.temporal.io](https://cloud.temporal.io).
2. Create a namespace (**Namespaces → Create Namespace**): pick a name and
   a region near you. The full namespace ID is `<name>.<account-id>` —
   copy it exactly as shown; you'll need the whole thing.

## Part B: Create an API key

1. Go to **Settings → API Keys** (or your profile → API Keys) and create
   one. Give it a description like `workshop`, an expiry, and make sure the
   owning identity has access to your namespace.
2. Copy the key (`tmprl_...`) immediately — it's shown once.

API keys are bearer credentials: whoever holds the key acts as you. Treat
it like a password, and prefer short expirations for experiments like this.

## Part C: Point your environment at the cloud

API-key auth uses Temporal Cloud's **regional gRPC endpoints**:
`<region>.<cloud-provider>.api.temporal.io:7233` — use the region you chose
in Part A (e.g. `us-east-1.aws.api.temporal.io:7233`).

```bash
export TEMPORAL_ADDRESS="us-east-1.aws.api.temporal.io:7233"   # your region here
export TEMPORAL_NAMESPACE="<name>.<account-id>"                # from Part A
export TEMPORAL_API_KEY="tmprl_..."                            # from Part B
export TEMPORAL_TLS=true
```

The `temporal` CLI reads these environment variables, so it's now pointed
at your Cloud namespace too. Verify the connection before touching any
code:

```bash
temporal workflow list
```

An empty list (no error) means you're authenticated against your namespace.

> To go back to your local dev server in the same shell later:
> `unset TEMPORAL_ADDRESS TEMPORAL_NAMESPACE TEMPORAL_API_KEY TEMPORAL_TLS`

## Part D: Run the cloud worker

Look at [worker.py](worker.py) — the `Client.connect()` call now takes the
address, the `namespace`, your `api_key`, and `tls=True`. That's the entire
migration. Run it (same shell, so it inherits your env vars):

```bash
uv run exercises/08-to-the-cloud/worker.py
```

```
Worker connected to <your-namespace> on Temporal Cloud. Ctrl-C to stop.
```

Your laptop is now a worker fleet (population: 1) for a production-grade
Temporal Service.

## Part E: Run a workflow on Temporal Cloud

In another terminal (export the same four variables there), start the
workshop's very first workflow — unchanged:

```bash
temporal workflow start \
  --type TaglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id cloud-tagline-1 \
  --input '"CatNip Cola"'
temporal workflow result -w cloud-tagline-1
```

Then open your namespace in [cloud.temporal.io](https://cloud.temporal.io):
there's `cloud-tagline-1`, with the same event history you learned to read
in this workshop — same UI, same events, running on the managed service.

## Where this goes next

- **Workers in production** run exactly like this one — a plain process
  with a Client connection — on your VMs, containers, or Kubernetes. Run at
  least two for availability.
- **mTLS** is the alternative to API keys for service-to-service auth;
  API keys are the fastest path and fine for getting started.
- The rest of the path: [docs.temporal.io/cloud](https://docs.temporal.io/cloud)
  for namespaces, API keys, and limits;
  [learn.temporal.io](https://learn.temporal.io) for the full courses.

That's the workshop, end to end: a fragile script, made durable, debugged
through its own history, gated on a human — and now running against the
real thing. 🥤🐈
