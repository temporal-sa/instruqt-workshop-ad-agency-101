package workshop;

import io.temporal.workflow.WorkflowInterface;
import io.temporal.workflow.WorkflowMethod;

@WorkflowInterface
public interface TaglineWorkflow {
  @WorkflowMethod
  String generate(String brand);
}
