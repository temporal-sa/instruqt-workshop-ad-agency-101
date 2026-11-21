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
        // TODO: Part B — return the tagline: the brand name, a colon and a space,
        // then "Taste the Meow!"  e.g.  "CatNip Cola: Taste the Meow!"
        return "TODO";
    }
}
