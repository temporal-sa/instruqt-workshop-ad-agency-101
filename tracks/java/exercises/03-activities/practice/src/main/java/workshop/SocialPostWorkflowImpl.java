package workshop;

import io.temporal.activity.ActivityOptions;
import io.temporal.workflow.Workflow;
import java.time.Duration;
import java.util.List;

public class SocialPostWorkflowImpl implements SocialPostWorkflow {
  private static final String BRAND = "CatNip Cola";
  private final TaglineActivities taglineActivities =
      Workflow.newActivityStub(
          TaglineActivities.class,
          ActivityOptions.newBuilder()
              .setStartToCloseTimeout(Duration.ofSeconds(10))
              .build());
  private final HashtagActivities hashtagActivities =
      Workflow.newActivityStub(
          HashtagActivities.class,
          ActivityOptions.newBuilder()
              .setStartToCloseTimeout(Duration.ofSeconds(10))
              .build());

  @Override
  public String createPost(String channel) {
    String tagline = taglineActivities.generateTagline(BRAND);
    // TODO: Part C — use the typed stub defined above:
    // List<String> hashtags = hashtagActivities.fetchHashtags(channel);
    List<String> hashtags = List.of();
    return tagline + " " + String.join(" ", hashtags);
  }
}
