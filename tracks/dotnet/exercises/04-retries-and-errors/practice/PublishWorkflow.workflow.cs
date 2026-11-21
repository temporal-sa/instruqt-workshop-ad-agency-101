using Temporalio.Workflows;

namespace Workshop;

[Workflow]
public class PublishWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string channel)
    {
        return await Workflow.ExecuteActivityAsync(
            (PublishActivities a) => a.PublishPostAsync(channel),
            new ActivityOptions
            {
                StartToCloseTimeout = TimeSpan.FromSeconds(10),
                // TODO: Part C — add a custom retry policy:
                // RetryPolicy = new()
                // {
                //     InitialInterval = TimeSpan.FromSeconds(1),
                //     BackoffCoefficient = 2,
                //     MaximumInterval = TimeSpan.FromSeconds(10),
                // },
            });
    }
}
