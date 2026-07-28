# Exercise 7: Bonus — Event History and replay

**Goal:** inspect the durable record and replay it against current Workflow
code.

Export the completed capstone history:

```bash
temporal workflow show -w campaign-summer-splash -o json \
  > exercises/07-bonus-observability/history.json
```

Replay against your `practice/workflows.ts`:

```bash
npx tsx exercises/07-bonus-observability/replay.ts
```

`Worker.runReplayHistory` executes Workflow code against the recorded
commands without calling the real Activities. Success means the current
Workflow remains deterministic and compatible with that history.

As an experiment, reorder `reserveBudget` and `validateCreative`, rerun the
replay, and observe the non-determinism error. Restore the order afterward.

Useful history queries:

```bash
temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].eventType] | group_by(.) | map({event: .[0], count: length})'

temporal workflow show -w campaign-summer-splash -o json |
  jq '[.events[].activityTaskStartedEventAttributes.attempt // 0] | max'
```
