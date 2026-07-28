package workshop;

import io.temporal.workflow.WorkflowInterface;
import io.temporal.workflow.WorkflowMethod;

@WorkflowInterface
public interface CampaignWorkflow {
  @WorkflowMethod
  LaunchReport launch(String campaign);
}
