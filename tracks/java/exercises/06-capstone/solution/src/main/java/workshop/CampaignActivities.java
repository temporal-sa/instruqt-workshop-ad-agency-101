package workshop;

import io.temporal.activity.ActivityInterface;
import java.util.List;

@ActivityInterface
public interface CampaignActivities {
  String validateCreative(String campaign);

  String reserveBudget(String campaign);

  String publishToChannel(String campaign, String channel);

  LaunchReport generateLaunchReport(
      String campaign, String creativeId, String reservationId, List<String> placements);
}
