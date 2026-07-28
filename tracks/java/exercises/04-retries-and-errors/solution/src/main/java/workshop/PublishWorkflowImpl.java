package workshop;

import io.temporal.activity.ActivityOptions;
import io.temporal.common.RetryOptions;
import io.temporal.workflow.Workflow;
import java.time.Duration;

public class PublishWorkflowImpl implements PublishWorkflow {
  private final PublishActivities activities =
      Workflow.newActivityStub(
          PublishActivities.class,
          ActivityOptions.newBuilder()
              .setStartToCloseTimeout(Duration.ofSeconds(10))
              .setRetryOptions(
                  RetryOptions.newBuilder()
                      .setInitialInterval(Duration.ofSeconds(1))
                      .setBackoffCoefficient(2)
                      .setMaximumInterval(Duration.ofSeconds(10))
                      .build())
              .build());

  @Override
  public String publish(String channel) {
    return activities.publishPost(channel);
  }
}
