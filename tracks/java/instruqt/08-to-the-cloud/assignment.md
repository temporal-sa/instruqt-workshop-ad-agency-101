---
slug: to-the-cloud
type: challenge
title: '8. Take-home: to the cloud'
teaser: Point your worker at a real Temporal Cloud namespace. API key, TLS, zero code
  changes.
notes:
- type: text
  contents: |-
    # Exercise 8: Take-home — connect to Temporal Cloud
    Complete the exercise using the language-specific SDK.
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
