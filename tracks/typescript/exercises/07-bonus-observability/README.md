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

Still in the [button label="CLI"](tab-4) tab, replay against your
`practice/workflows.ts`:

```bash,run
npx tsx exercises/07-bonus-observability/replay.ts
```

`Worker.runReplayHistory` executes Workflow code against the recorded
commands without calling the real Activities. Success means the current
Workflow remains deterministic and compatible with that history.

# Step 4: Query the history

Run these useful queries in the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].eventType] | group_by(.) | map({event: .[0], count: length})'
```

```bash,run
temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```

When replay succeeds, hit **Check**.

# Stretch: break replay deliberately

In the [button label="Editor"](tab-0) tab, reorder `reserveBudget` and
`validateCreative`, then rerun the replay command from the
[button label="CLI"](tab-4) tab. Observe the non-determinism error and
restore the original order afterward.
