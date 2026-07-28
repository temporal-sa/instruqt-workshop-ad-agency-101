package workshop;

import io.temporal.workflow.SignalMethod;
import io.temporal.workflow.WorkflowInterface;
import io.temporal.workflow.WorkflowMethod;

@WorkflowInterface
public interface CampaignApprovalWorkflow {
  @WorkflowMethod
  ApprovalReport awaitApproval(String campaign, int approvalDeadlineSeconds);

  @SignalMethod
  void approve(String approver);
}
