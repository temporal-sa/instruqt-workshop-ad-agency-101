# Exercise 3: Activities

**Goal:** move network I/O into an Activity and call it from the Workflow
through a typed lambda.

Workflow code must be deterministic and cannot call `HttpClient`.
Activities are ordinary methods marked `[Activity]` and may perform
network, file, or database I/O. The Workflow schedules them by naming the
method in a lambda:

```csharp
var hashtags = await Workflow.ExecuteActivityAsync(
    (SocialActivities a) => a.FetchHashtagsAsync(channel),
    new ActivityOptions { StartToCloseTimeout = TimeSpan.FromSeconds(10) });
```

The lambda is never invoked inside the Workflow. The SDK reads the method
and arguments from it, then schedules an Activity Task named
`FetchHashtags` (the method name without its `Async` suffix).

# Step 1: Trace the worked Activity

In the [button label="Editor"](tab-0) tab, open
`03-activities/practice/`:

- `SocialActivities.cs` contains the worked `GenerateTaglineAsync`
  Activity.
- `SocialPostWorkflow.workflow.cs` schedules `GenerateTaglineAsync` with
  `Workflow.ExecuteActivityAsync` and awaits it.
- `Program.cs` registers `GenerateTaglineAsync` with the Worker.

That is the complete path: `[Activity]` method → typed Workflow call →
Worker registration.

# Step 2: Implement `FetchHashtagsAsync`

In `SocialActivities.cs`, add an `[Activity]` method
`FetchHashtagsAsync(channel)`. Fetch `/trending/<channel>` and return the
decoded hashtag list:

```csharp
[Activity]
public async Task<List<string>> FetchHashtagsAsync(string channel)
{
    var body = await GetJsonAsync($"/trending/{channel}");
    return body["hashtags"]!.AsArray().Select(tag => (string)tag!).ToList();
}
```

# Step 3: Call the Activity from the Workflow

In `SocialPostWorkflow.workflow.cs`, replace the empty hashtag list inside
`RunAsync`:

```csharp
var hashtags = new List<string>();
```

with the Activity call:

```csharp
var hashtags = await Workflow.ExecuteActivityAsync(
    (SocialActivities a) => a.FetchHashtagsAsync(channel), activityOptions);
```

This schedules an Activity Task; it does not call the networked
implementation inside the Workflow.

# Step 4: Register the Activity

In `Program.cs`, add the new method to the Worker options:

```csharp
.AddActivity(activities.GenerateTaglineAsync)
.AddActivity(activities.FetchHashtagsAsync)
```

# Step 5: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
dotnet run --project exercises/03-activities/practice/SocialPostWorker.csproj
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
