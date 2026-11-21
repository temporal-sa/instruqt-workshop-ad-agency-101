using Microsoft.Extensions.Logging;
using Temporalio.Workflows;

namespace Workshop;

[Workflow]
public class CampaignApprovalWorkflow
{
    private string? approvedBy;

    // The Signal is named "approve", matching `temporal workflow signal --name approve`.
    [WorkflowSignal("approve")]
    public async Task ApproveAsync(string approver)
    {
        approvedBy = approver;
    }

    [WorkflowRun]
    public async Task<ApprovalReport> RunAsync(string campaign, int approvalDeadlineSeconds)
    {
        Workflow.Logger.LogInformation(
            "Campaign {Campaign} awaiting client approval for {Seconds}s",
            campaign,
            approvalDeadlineSeconds);

        var received = await Workflow.WaitConditionAsync(
            () => approvedBy != null,
            TimeSpan.FromSeconds(approvalDeadlineSeconds));

        if (!received)
        {
            return new ApprovalReport(
                campaign, "EXPIRED", null, "escalate to the account exec (by fax, probably)");
        }
        return new ApprovalReport(campaign, "APPROVED", approvedBy, "cleared for launch");
    }
}
