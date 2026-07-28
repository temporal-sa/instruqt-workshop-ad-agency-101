package workshop;

import io.temporal.activity.ActivityOptions;
import io.temporal.workflow.Workflow;
import java.time.Duration;

public class PublishWorkflowImpl implements PublishWorkflow {
  private final PublishActivities activities =
      Workflow.newActivityStub(
          PublishActivities.class,
          ActivityOptions.newBuilder()
              .setStartToCloseTimeout(Duration.ofSeconds(10))
              // TODO: Part C — set RetryOptions with a 1-second initial
              // interval, coefficient 2, and 10-second maximum interval.
              .build());

  @Override
  public String publish(String channel) {
    return activities.publishPost(channel);
  }
}
