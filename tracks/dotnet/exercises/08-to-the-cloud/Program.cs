// The same Worker as exercise 2, connected to Temporal Cloud.
// Workflow code and Task Queue configuration are unchanged.

using Temporalio.Client;
using Temporalio.Worker;
using Workshop;

string[] required = ["TEMPORAL_ADDRESS", "TEMPORAL_NAMESPACE", "TEMPORAL_API_KEY"];
var missing = required
    .Where(name => string.IsNullOrEmpty(Environment.GetEnvironmentVariable(name)))
    .ToList();
if (missing.Count > 0)
{
    Console.Error.WriteLine($"Set {string.Join(", ", missing)} first — see this exercise's README.");
    return 1;
}

var address = Environment.GetEnvironmentVariable("TEMPORAL_ADDRESS")!;
var @namespace = Environment.GetEnvironmentVariable("TEMPORAL_NAMESPACE")!;
var apiKey = Environment.GetEnvironmentVariable("TEMPORAL_API_KEY")!;

var client = await TemporalClient.ConnectAsync(new(address)
{
    Namespace = @namespace,
    ApiKey = apiKey,
    Tls = new(),
});

using var worker = new TemporalWorker(
    client,
    new TemporalWorkerOptions(taskQueue: "tagline-tasks")
        .AddWorkflow<TaglineWorkflow>());

using var shutdown = new CancellationTokenSource();
Console.CancelKeyPress += (_, eventArgs) =>
{
    eventArgs.Cancel = true;
    shutdown.Cancel();
};

Console.WriteLine($"Worker connected to {@namespace} on Temporal Cloud. Ctrl-C to stop.");
try
{
    await worker.ExecuteAsync(shutdown.Token);
}
catch (OperationCanceledException)
{
    Console.WriteLine("Worker stopped.");
}
return 0;
