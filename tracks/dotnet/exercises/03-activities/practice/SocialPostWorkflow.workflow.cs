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

        // TODO: Part C — replace the empty list with the Activity call:
        // var hashtags = await Workflow.ExecuteActivityAsync(
        //     (SocialActivities a) => a.FetchHashtagsAsync(channel), activityOptions);
        // The lambda names the Activity to schedule; the Workflow never calls
        // the networked implementation directly.
        var hashtags = new List<string>();

        return $"{tagline} {string.Join(' ', hashtags)}";
    }
}
