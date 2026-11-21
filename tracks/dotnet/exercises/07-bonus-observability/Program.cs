// Replay the capstone history against the learner's current Workflow code.
//
// First export:
//   temporal workflow show -w campaign-summer-splash -o json \
//     > exercises/07-bonus-observability/history.json
// Then:
//   dotnet run --project exercises/07-bonus-observability/Replay.csproj

using System.Runtime.CompilerServices;
using Temporalio.Common;
using Temporalio.Worker;
using Workshop;

var historyPath = Path.Combine(SourceDirectory(), "history.json");
if (!File.Exists(historyPath))
{
    Console.Error.WriteLine(
        "history.json not found. Export it first:\n" +
        "  temporal workflow show -w campaign-summer-splash -o json " +
        "> exercises/07-bonus-observability/history.json");
    return 1;
}

var replayer = new WorkflowReplayer(
    new WorkflowReplayerOptions().AddWorkflow<CampaignWorkflow>());
await replayer.ReplayWorkflowAsync(
    WorkflowHistory.FromJson("campaign-summer-splash", await File.ReadAllTextAsync(historyPath)));

Console.WriteLine("Replay OK: your Workflow code is compatible with the recorded history.");
return 0;

static string SourceDirectory([CallerFilePath] string path = "") => Path.GetDirectoryName(path)!;
