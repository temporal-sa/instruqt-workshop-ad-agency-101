using Temporalio.Common;
using Temporalio.Workflows;

namespace Workshop;

[Workflow]
public class CampaignWorkflow
{
    private static readonly string[] Channels = ["meowta", "catstagram", "pettok"];

    private readonly ActivityOptions defaultOptions = new()
    {
        StartToCloseTimeout = TimeSpan.FromSeconds(10),
    };

    private readonly ActivityOptions publishingOptions = new()
    {
        StartToCloseTimeout = TimeSpan.FromSeconds(10),
        RetryPolicy = new RetryPolicy
        {
            InitialInterval = TimeSpan.FromSeconds(1),
            BackoffCoefficient = 2,
            MaximumInterval = TimeSpan.FromSeconds(10),
            NonRetryableErrorTypes = ["ChannelPolicyError"],
        },
    };

    [WorkflowRun]
    public async Task<LaunchReport> RunAsync(string campaign)
    {
        var creativeId = await Workflow.ExecuteActivityAsync(
            (CampaignActivities a) => a.ValidateCreativeAsync(campaign), defaultOptions);
        var reservationId = await Workflow.ExecuteActivityAsync(
            (CampaignActivities a) => a.ReserveBudgetAsync(campaign), defaultOptions);

        var placements = new List<string>();
        foreach (var channel in Channels)
        {
            placements.Add(await Workflow.ExecuteActivityAsync(
                (CampaignActivities a) => a.PublishToChannelAsync(campaign, channel),
                publishingOptions));
        }

        return await Workflow.ExecuteActivityAsync(
            (CampaignActivities a) => a.GenerateLaunchReportAsync(
                campaign, creativeId, reservationId, placements),
            defaultOptions);
    }
}
