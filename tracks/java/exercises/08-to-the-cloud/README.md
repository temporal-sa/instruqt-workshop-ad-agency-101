# Exercise 8: Take-home — connect to Temporal Cloud

The Workflow implementation and Task Queue stay the same. Only the Worker
connection changes to a Cloud endpoint authenticated with an API key.

```bash
export TEMPORAL_ADDRESS="<region>.<provider>.api.temporal.io:7233"
export TEMPORAL_NAMESPACE="<namespace>.<account-id>"
export TEMPORAL_API_KEY="<api-key>"
```

Start the Worker:

```bash
mvn -q -f exercises/08-to-the-cloud/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.CloudWorker
```

Configure the CLI and start the same Workflow type:

```bash
temporal env set cloud \
  --address "$TEMPORAL_ADDRESS" \
  --namespace "$TEMPORAL_NAMESPACE" \
  --api-key "$TEMPORAL_API_KEY" \
  --tls

temporal workflow start --env cloud \
  --type TaglineWorkflow \
  --task-queue tagline-tasks \
  --workflow-id cloud-tagline-1 \
  --input '"CatNip Cola"'
temporal workflow result --env cloud -w cloud-tagline-1
```

Keep API keys out of source control and load them from the deployment
platform's secret manager in production.
