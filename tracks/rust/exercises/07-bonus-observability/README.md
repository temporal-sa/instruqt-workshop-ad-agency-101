# Exercise 7: Bonus — Event History and replay

**Goal:** inspect the durable record and replay it against current Workflow
code.

# Step 1: Inspect Event History

Open `campaign-summer-splash` in the
[button label="Temporal UI"](tab-5) tab. Inspect the PetTok Activity attempt
count, the input to `CampaignActivities::reserve_budget`, and the Worker
identity before and after the process restart.

# Step 2: Export the history

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow show -w campaign-summer-splash -o json \
  > exercises/07-bonus-observability/history.json
```

# Step 3: Replay it

Still in the [button label="CLI"](tab-4) tab, replay against your
`06-capstone/practice/workflows.rs`:

```bash,run
cargo run -q --bin replay
```

`replay.rs` compiles your exercise 6 practice code, fetches the
`campaign-summer-splash` Event History, and hands it to the SDK's
`WorkflowReplayer`. The replayer executes the Workflow against the recorded
commands without calling the real Activities. Success means the current
Workflow remains deterministic and compatible with that history.

> [!NOTE]
> The Rust SDK's history loader reads its own JSON encoding, not the
> proto-JSON that `temporal workflow show -o json` writes. That's why
> `replay.rs` fetches the history from the Temporal Service rather than
> reading `history.json`. The replay itself is the same, and the exported
> file stays useful for offline inspection and sharing.

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

In the [button label="Editor"](tab-0) tab, reorder the `reserve_budget` and
`validate_creative` calls in `06-capstone/practice/workflows.rs`, then rerun
the replay command from the [button label="CLI"](tab-4) tab. Observe the
nondeterminism error and restore the original order afterward.
