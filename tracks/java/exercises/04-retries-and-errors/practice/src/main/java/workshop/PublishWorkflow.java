package workshop;

import io.temporal.workflow.WorkflowInterface;
import io.temporal.workflow.WorkflowMethod;

@WorkflowInterface
public interface PublishWorkflow {
  @WorkflowMethod
  String publish(String channel);
}
