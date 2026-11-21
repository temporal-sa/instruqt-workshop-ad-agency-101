# Exercise 3: Activities

**Goal:** move network I/O into an Activity and call it from a Workflow
through a typed method reference.

Go Workflow code has no sandbox. Never perform network, file, database,
clock, random, or native goroutine operations in it. Put side effects in
Activities: exported methods on a struct, with `context.Context` first.
The Workflow names an Activity with a method reference on a nil pointer:

```go
var hashtagActivities *HashtagActivities

ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
	StartToCloseTimeout: 10 * time.Second,
})
err := workflow.ExecuteActivity(ctx, hashtagActivities.FetchHashtags, channel).Get(ctx, &hashtags)
```

# Step 1: Trace the worked Activity

In the [button label="Editor"](tab-0) tab, open
`03-activities/practice/`:

- `activities.go` defines `TaglineActivities.GenerateTagline`, which
  performs the AdNet request.
- `workflow.go` executes `taglineActivities.GenerateTagline` and waits for
  its result with `.Get`.
- `worker/main.go` registers `&social.TaglineActivities{}`.

That is the complete path: Activity method → typed Workflow call → Worker
registration.

# Step 2: Complete `FetchHashtags`

In `activities.go`, finish `HashtagActivities.FetchHashtags`. The HTTP
request and JSON decoding are already provided. Return the decoded list:

```go
return body.Hashtags, nil
```

# Step 3: Call the Activity from the Workflow

In `workflow.go`, replace the empty list inside `SocialPostWorkflow`:

```go
hashtags := []string{}
```

with the Activity call:

```go
var hashtags []string
err = workflow.ExecuteActivity(ctx, hashtagActivities.FetchHashtags, channel).Get(ctx, &hashtags)
if err != nil {
	return "", err
}
```

This does not call `FetchHashtags` directly. It tells Temporal to schedule
a `FetchHashtags` Activity Task and waits durably for its result.

# Step 4: Register the Activity

In `worker/main.go`, register the new struct next to the existing one:

```go
w.RegisterActivity(&social.TaglineActivities{})
w.RegisterActivity(&social.HashtagActivities{})
```

`RegisterActivity` registers every exported method of the struct. The
method name becomes the Activity Type.

# Step 5: Start the Worker

In the [button label="Worker"](tab-3) tab, stop any previous Worker with
Ctrl-C, then run:

```bash,run
go run ./exercises/03-activities/practice/worker
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

If an Activity is executed but not registered, the Activity remains pending
and the Worker reports `unable to find activityType`. Registration is the
link between an Activity Task on a queue and its implementation.

Open `social-post-1` in the [button label="Temporal UI"](tab-5) tab and find
both completed Activities in Event History. Then hit **Check**.

> [!NOTE]
> Stuck? Compare with `03-activities/solution/` in the
> [button label="Editor"](tab-0) tab.
