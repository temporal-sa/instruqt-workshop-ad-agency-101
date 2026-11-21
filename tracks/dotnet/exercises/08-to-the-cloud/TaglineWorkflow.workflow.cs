using Microsoft.Extensions.Logging;
using Temporalio.Workflows;

namespace Workshop;

[Workflow]
public class TaglineWorkflow
{
    [WorkflowRun]
    public async Task<string> RunAsync(string brand)
    {
        Workflow.Logger.LogInformation("Generating tagline for {Brand}", brand);
        return $"{brand}: Taste the Meow!";
    }
}
