# Exercise 7: Bonus — Event History and replay

**Goal:** inspect the durable record and replay it against current Workflow
code.

# Step 1: Inspect Event History

Open `campaign-summer-splash` in the
[button label="Temporal UI"](tab-5) tab. Inspect the PetTok Activity attempt
count, the input to `reserveBudget`, and the Worker identity before and after
the process restart.

# Step 2: Export the history

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow show -w campaign-summer-splash -o json \
  > exercises/07-bonus-observability/history.json
```

# Step 3: Replay it

Still in the [button label="CLI"](tab-4) tab:

```bash,run
mvn -q -f exercises/07-bonus-observability/pom.xml \
  compile exec:java -Dexec.mainClass=workshop.Replay
```

`WorkflowReplayer` compares commands produced by
`CampaignWorkflowImpl` with recorded Event History. It does not call real
Activities.

# Step 4: Query the history

Run this query in the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```

When replay succeeds, hit **Check**.

# Stretch: break replay deliberately

In the [button label="Editor"](tab-0) tab, reorder budget reservation and
creative validation. Rerun the replay command from the
[button label="CLI"](tab-4) tab, observe `NonDeterministicException`, and
restore the original order afterward.
