using Temporalio.Client;
using Temporalio.Worker;
using Workshop;

var client = await TemporalClient.ConnectAsync(new("localhost:7233"));

var activities = new SocialActivities();

using var worker = new TemporalWorker(
    client,
    new TemporalWorkerOptions(taskQueue: "social-tasks")
        .AddWorkflow<SocialPostWorkflow>()
        .AddActivity(activities.GenerateTaglineAsync)
        // TODO: Part D — register FetchHashtagsAsync too:
        // .AddActivity(activities.FetchHashtagsAsync)
    );

using var shutdown = new CancellationTokenSource();
Console.CancelKeyPress += (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    shutdown.Cancel();
};

Console.WriteLine("Worker started on task queue 'social-tasks'. Ctrl-C to stop.");
try
{
    await worker.ExecuteAsync(shutdown.Token);
}
catch (OperationCanceledException)
{
    Console.WriteLine("Worker stopped.");
}
