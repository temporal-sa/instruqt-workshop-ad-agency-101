using Temporalio.Common;
using Temporalio.Workflows;

namespace Workshop;

[Workflow]
public class CampaignWorkflow
{
    private static readonly string[] Channels = ["meowta", "catstagram", "pettok"];

    [WorkflowRun]
    public async Task<LaunchReport> RunAsync(string campaign)
    {
        // This used to be LaunchCampaignAsync() in exercise 1:
        //
        // var creativeId = await ValidateCreativeAsync(campaign);
        // var reservationId = await ReserveBudgetAsync(campaign);
        // var placements = new List<string>();
        // foreach (var channel in Channels)
        // {
        //     placements.Add(await PublishToChannelAsync(campaign, channel));
        // }
        // return GenerateLaunchReport(campaign, creativeId, reservationId, placements);
        //
        // TODO: Part C — rebuild the sequence above with
        // Workflow.ExecuteActivityAsync((CampaignActivities a) => a.SomethingAsync(...), options).
        // Give every Activity a 10-second StartToCloseTimeout. Give the
        // publishing call a RetryPolicy whose NonRetryableErrorTypes includes
        // "ChannelPolicyError".
        throw new NotImplementedException("TODO: Part C");
    }
}
