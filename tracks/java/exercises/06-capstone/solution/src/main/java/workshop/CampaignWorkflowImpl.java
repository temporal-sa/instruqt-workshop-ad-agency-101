package workshop;

import io.temporal.activity.ActivityOptions;
import io.temporal.common.RetryOptions;
import io.temporal.workflow.Workflow;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

public class CampaignWorkflowImpl implements CampaignWorkflow {
  private final CampaignActivities activities =
      Workflow.newActivityStub(
          CampaignActivities.class,
          ActivityOptions.newBuilder()
              .setStartToCloseTimeout(Duration.ofSeconds(10))
              .build());
  private final CampaignActivities publishingActivities =
      Workflow.newActivityStub(
          CampaignActivities.class,
          ActivityOptions.newBuilder()
              .setStartToCloseTimeout(Duration.ofSeconds(10))
              .setRetryOptions(
                  RetryOptions.newBuilder()
                      .setInitialInterval(Duration.ofSeconds(1))
                      .setBackoffCoefficient(2)
                      .setMaximumInterval(Duration.ofSeconds(10))
                      .setDoNotRetry("ChannelPolicyError")
                      .build())
              .build());

  @Override
  public LaunchReport launch(String campaign) {
    String creativeId = activities.validateCreative(campaign);
    String reservationId = activities.reserveBudget(campaign);
    List<String> placements = new ArrayList<>();
    for (String channel : List.of("meowta", "catstagram", "pettok")) {
      placements.add(publishingActivities.publishToChannel(campaign, channel));
    }
    return activities.generateLaunchReport(
        campaign, creativeId, reservationId, placements);
  }
}
