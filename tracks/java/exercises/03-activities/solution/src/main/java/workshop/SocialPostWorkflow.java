package workshop;

import io.temporal.workflow.WorkflowInterface;
import io.temporal.workflow.WorkflowMethod;

@WorkflowInterface
public interface SocialPostWorkflow {
  @WorkflowMethod
  String createPost(String channel);
}
