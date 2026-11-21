# Exercise 3: Activities

**Goal:** move network I/O into an Activity and call it from a Workflow with
`ctx.execute_activity`.

Workflow code must be deterministic: no network, file, database, clock,
random, or thread operations. Rust has no Workflow sandbox, so this is a
rule you follow by design. Side effects go in Activities: async methods in
an `#[activities]` impl block, each marked `#[activity]`:

```rust
pub struct HashtagActivities;

#[activities]
impl HashtagActivities {
    #[activity]
    pub async fn fetch_hashtags(
        _ctx: ActivityContext,
        channel: String,
    ) -> Result<Vec<String>, ActivityError> {
        // ...
    }
}
```

The macro names each Activity `<Type>::<method>`, so this one is
`HashtagActivities::fetch_hashtags`.

# Step 1: Trace the worked Activity

In the [button label="Editor"](tab-0) tab, open
`03-activities/practice/`:

- `activities.rs` contains the worked `TaglineActivities::generate_tagline`
  Activity.
- `workflows.rs` schedules it with `ctx.execute_activity` and awaits the
  result.
- `worker.rs` registers `TaglineActivities` with the Worker.

That is the complete path: Activity method → `ctx.execute_activity` in the
Workflow → Worker registration.

# Step 2: Implement `fetch_hashtags`

In `activities.rs`, finish `HashtagActivities::fetch_hashtags`. Fetch
`/trending/<channel>` and return the decoded hashtag list:

```rust
let body = get_json(&format!("/trending/{channel}")).await?;
Ok(serde_json::from_value(body["hashtags"].clone())?)
```

# Step 3: Call the Activity from the Workflow

In `workflows.rs`, replace the empty hashtag list inside `run` with the
Activity call:

```rust
let hashtags = ctx
    .execute_activity(HashtagActivities::fetch_hashtags, channel, activity_options())
    .await?;
```

This does not call the method directly. It tells Temporal to schedule a
`HashtagActivities::fetch_hashtags` Activity Task and wait durably for its
result.

# Step 4: Register the Activity

In `worker.rs`, register the new Activities next to the existing ones:

```rust
.register_activities(TaglineActivities)
.register_activities(HashtagActivities)
```

# Step 5: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
cargo run -q --bin social-post-worker
```

# Step 6: Start the Workflow

In the [button label="CLI"](tab-4) tab:

```bash,run
temporal workflow start \
  --type SocialPostWorkflow \
  --task-queue social-tasks \
  --workflow-id social-post-1 \
  --input '"catstagram"'
```

```bash,run
temporal workflow result -w social-post-1
```

Expected output contains `CatNip Cola: Taste the Meow!`,
`#CatsOfCatstagram`, and `#SummerSplash`.

If an Activity is scheduled but not registered, the Activity remains
pending and the Worker reports that the Activity type is not registered.
Registration is the link between an Activity Task on a queue and its
implementation.

Open `social-post-1` in the [button label="Temporal UI"](tab-5) tab and find
both completed Activities in Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `03-activities/solution/` in the
> [button label="Editor"](tab-0) tab.
