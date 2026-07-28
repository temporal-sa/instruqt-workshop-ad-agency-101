# Exercise 8: Take-home — connect to Temporal Cloud

The Workflow code and Task Queue stay the same. Only the Worker connection
changes from the local default to a TLS connection authenticated with an API
key.

Create a Temporal Cloud namespace and API key, then export:

```bash
export TEMPORAL_ADDRESS="<region>.<provider>.api.temporal.io:7233"
export TEMPORAL_NAMESPACE="<namespace>.<account-id>"
export TEMPORAL_API_KEY="<api-key>"
```

Start the Cloud Worker:

```bash
npx tsx exercises/08-to-the-cloud/worker.ts
```

In another terminal, configure the CLI and start the same Workflow type:

```bash
temporal env set cloud \
  --address "$TEMPORAL_ADDRESS" \
  --namespace "$TEMPORAL_NAMESPACE" \
  --api-key "$TEMPORAL_API_KEY" \
  --tls

temporal workflow start --env cloud \
  --type taglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id cloud-tagline-1 \
  --input '"CatNip Cola"'
temporal workflow result --env cloud -w cloud-tagline-1
```

Keep API keys out of source control. Production Workers should obtain them
from the deployment platform's secret manager.
