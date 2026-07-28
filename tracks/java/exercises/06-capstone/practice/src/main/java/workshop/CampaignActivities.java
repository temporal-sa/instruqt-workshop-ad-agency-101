package workshop;

import io.temporal.activity.ActivityInterface;
import java.util.List;

// TODO: Part B — add @ActivityInterface. Java Activities use an annotated
// interface plus an ordinary implementation class.
public interface CampaignActivities {
  String validateCreative(String campaign);

  String reserveBudget(String campaign);

  String publishToChannel(String campaign, String channel);

  LaunchReport generateLaunchReport(
      String campaign, String creativeId, String reservationId, List<String> placements);
}
