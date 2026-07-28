# Exercise 8: Take-home — connect to Temporal Cloud

The Workflow code and Task Queue stay the same. Only the Worker connection
changes from the local default to a TLS connection authenticated with an API
key.

# Step 1: Download the workshop

This is a take-home exercise because it requires a Temporal Cloud account.
The [button label="Download"](tab-6) tab contains the complete workshop.

# Step 2: Configure Cloud credentials

Create a Temporal Cloud namespace and API key. In the
[button label="CLI"](tab-4) tab, replace the placeholders and export:

```bash
export TEMPORAL_ADDRESS="<region>.<provider>.api.temporal.io:7233"
export TEMPORAL_NAMESPACE="<namespace>.<account-id>"
export TEMPORAL_API_KEY="<api-key>"
```

The credential block deliberately has no run button: replace its
placeholders before entering it. Verify the CLI connection:

```bash,run
temporal workflow list \
  --address "$TEMPORAL_ADDRESS" \
  --namespace "$TEMPORAL_NAMESPACE" \
  --api-key "$TEMPORAL_API_KEY" \
  --tls
```

# Step 3: Start the Cloud Worker

Open `08-to-the-cloud/worker.ts` in the
[button label="Editor"](tab-0) tab and inspect its `NativeConnection`
configuration.

Export the same three environment variables in the
[button label="Worker"](tab-3) tab, then run:

```bash,run
npx tsx exercises/08-to-the-cloud/worker.ts
```

# Step 4: Run a Workflow in Cloud

Back in the [button label="CLI"](tab-4) tab, save the environment:

```bash,run
temporal env set cloud \
  --address "$TEMPORAL_ADDRESS" \
  --namespace "$TEMPORAL_NAMESPACE" \
  --api-key "$TEMPORAL_API_KEY" \
  --tls
```

Start the same Workflow type:

```bash,run
temporal workflow start --env cloud \
  --type taglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id cloud-tagline-1 \
  --input '"CatNip Cola"'
```

```bash,run
temporal workflow result --env cloud -w cloud-tagline-1
```

Keep API keys out of source control. Production Workers should obtain them
from the deployment platform's secret manager.
