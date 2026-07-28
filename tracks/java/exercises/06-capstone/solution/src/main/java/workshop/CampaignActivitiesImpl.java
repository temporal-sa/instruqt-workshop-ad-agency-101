package workshop;

import io.temporal.activity.Activity;
import io.temporal.failure.ApplicationFailure;
import java.util.List;

public class CampaignActivitiesImpl implements CampaignActivities {
  private static String successful(AdNetClient.Response response, String field) {
    if (response.status() < 200 || response.status() >= 300) {
      throw new IllegalStateException(response.status() + ": " + response.body());
    }
    return (String) response.body().get(field);
  }

  @Override
  public String validateCreative(String campaign) {
    return successful(AdNetClient.post("/validate-creative", campaign), "creative_id");
  }

  @Override
  public String reserveBudget(String campaign) {
    return successful(AdNetClient.post("/reserve-budget", campaign), "reservation_id");
  }

  @Override
  public String publishToChannel(String campaign, String channel) {
    int attempt = Activity.getExecutionContext().getInfo().getAttempt();
    System.out.printf("Publishing to %s (attempt %d)%n", channel, attempt);
    AdNetClient.Response response = AdNetClient.post("/publish/" + channel, campaign);
    if (response.status() >= 400 && response.status() < 500) {
      throw ApplicationFailure.newNonRetryableFailure(
          channel + " rejected the campaign: " + response.body().get("error"),
          "ChannelPolicyError");
    }
    return successful(response, "placement_id");
  }

  @Override
  public LaunchReport generateLaunchReport(
      String campaign, String creativeId, String reservationId, List<String> placements) {
    return new LaunchReport(
        campaign, "LIVE", creativeId, reservationId, placements, placements.size());
  }
}
