using Temporalio.Workflows;

namespace Workshop;

[Workflow]
public class SocialPostWorkflow
{
    private const string Brand = "CatNip Cola";

    private readonly ActivityOptions activityOptions = new()
    {
        StartToCloseTimeout = TimeSpan.FromSeconds(10),
    };

    [WorkflowRun]
    public async Task<string> RunAsync(string channel)
    {
        var tagline = await Workflow.ExecuteActivityAsync(
            (SocialActivities a) => a.GenerateTaglineAsync(Brand), activityOptions);
        var hashtags = await Workflow.ExecuteActivityAsync(
            (SocialActivities a) => a.FetchHashtagsAsync(channel), activityOptions);
        return $"{tagline} {string.Join(' ', hashtags)}";
    }
}
