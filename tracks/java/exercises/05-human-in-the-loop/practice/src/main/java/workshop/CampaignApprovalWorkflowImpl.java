package workshop;

import io.temporal.workflow.Workflow;
import java.time.Duration;

public class CampaignApprovalWorkflowImpl implements CampaignApprovalWorkflow {
  private String approvedBy;

  @Override
  public void approve(String approver) {
    // TODO: Part B — record the approver so awaitApproval can observe it.
  }

  @Override
  public ApprovalReport awaitApproval(String campaign, int approvalDeadlineSeconds) {
    Workflow.getLogger(CampaignApprovalWorkflowImpl.class)
        .info("Campaign {} awaiting approval (deadline: {}s)", campaign, approvalDeadlineSeconds);

    // TODO: Part C — wait durably:
    // boolean received = Workflow.await(
    //     Duration.ofSeconds(approvalDeadlineSeconds),
    //     () -> approvedBy != null);
    boolean received = false;

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
