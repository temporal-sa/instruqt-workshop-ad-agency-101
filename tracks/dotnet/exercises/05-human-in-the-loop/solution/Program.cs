using Temporalio.Client;
using Temporalio.Worker;
using Workshop;

var client = await TemporalClient.ConnectAsync(new("localhost:7233"));

using var worker = new TemporalWorker(
    client,
    new TemporalWorkerOptions(taskQueue: "approval-tasks")
        .AddWorkflow<CampaignApprovalWorkflow>());

using var shutdown = new CancellationTokenSource();
Console.CancelKeyPress += (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    shutdown.Cancel();
};

Console.WriteLine("Worker started on task queue 'approval-tasks'. Ctrl-C to stop.");
try
{
    await worker.ExecuteAsync(shutdown.Token);
}
catch (OperationCanceledException)
{
    Console.WriteLine("Worker stopped.");
}
