package workshop;

import io.temporal.workflow.Workflow;
import java.time.Duration;

public class CampaignApprovalWorkflowImpl implements CampaignApprovalWorkflow {
  private String approvedBy;

  @Override
  public void approve(String approver) {
    approvedBy = approver;
  }

  @Override
  public ApprovalReport awaitApproval(String campaign, int approvalDeadlineSeconds) {
    Workflow.getLogger(CampaignApprovalWorkflowImpl.class)
        .info("Campaign {} awaiting approval (deadline: {}s)", campaign, approvalDeadlineSeconds);
    boolean received =
        Workflow.await(
            Duration.ofSeconds(approvalDeadlineSeconds),
            () -> approvedBy != null);
    if (!received) {
      return new ApprovalReport(
          campaign,
          "EXPIRED",
          null,
          "escalate to the account exec (by fax, probably)");
    }
    return new ApprovalReport(campaign, "APPROVED", approvedBy, "cleared for launch");
  }
}
