# Exercise 3: Activities

**Goal:** move network I/O into an Activity and call it from a Workflow
with `execute_activity`.

Workflow code must be deterministic. The Ruby SDK traces Workflow code and
rejects calls such as `Net::HTTP`, `File`, `sleep`, and `Time.now`. Put side
effects in an Activity: a class that subclasses
`Temporalio::Activity::Definition`. The Workflow schedules it by class:

```ruby
hashtags = Temporalio::Workflow.execute_activity(
  FetchHashtags, channel,
  start_to_close_timeout: 10
)
```

The Activity type defaults to the class name, `FetchHashtags`.

# Step 1: Trace the worked Activity

In the [button label="Editor"](tab-0) tab, open
`03-activities/practice/`:

- `activities.rb` contains the worked `GenerateTagline` Activity.
- `workflows.rb` schedules `GenerateTagline` with `execute_activity`.
- `worker.rb` registers `GenerateTagline` with the Worker.

That is the complete path: Activity class → `execute_activity` in the
Workflow → Worker registration.

# Step 2: Implement `FetchHashtags`

In `activities.rb`, define a `FetchHashtags` Activity. Fetch
`/trending/<channel>` and return the decoded hashtag list:

```ruby
class FetchHashtags < Temporalio::Activity::Definition
  def execute(channel)
    AdNet.get_json("/trending/#{channel}").fetch('hashtags')
  end
end
```

# Step 3: Call the Activity from the Workflow

In `workflows.rb`, replace the empty hashtag list inside
`SocialPostWorkflow#execute`:

```ruby
hashtags = []
```

with the Activity call:

```ruby
hashtags = Temporalio::Workflow.execute_activity(
  FetchHashtags, channel,
  start_to_close_timeout: 10
)
```

`execute_activity` schedules an Activity Task and waits durably for its
result; it does not run the networked code inside the Workflow.

# Step 4: Register the Activity

In `worker.rb`, register both Activity classes:

```ruby
activities: [GenerateTagline, FetchHashtags]
```

# Step 5: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
bundle exec ruby exercises/03-activities/practice/worker.rb
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
