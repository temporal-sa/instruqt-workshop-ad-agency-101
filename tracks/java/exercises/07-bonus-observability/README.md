# Exercise 7: Bonus — Event History and replay

**Goal:** inspect the durable record and replay it against current Workflow
code.

Export the capstone history:

```bash
temporal workflow show -w campaign-summer-splash -o json \
  > exercises/07-bonus-observability/history.json
```

Replay it:

```bash
mvn -q -f exercises/07-bonus-observability/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.Replay
```

`WorkflowReplayer` compares commands produced by
`CampaignWorkflowImpl` with recorded Event History. It does not call real
Activities.

As an experiment, reorder budget reservation and creative validation,
rerun replay, and observe `NonDeterministicException`. Restore the original
order afterward.

```bash
temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```
