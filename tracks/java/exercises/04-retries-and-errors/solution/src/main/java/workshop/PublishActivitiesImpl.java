package workshop;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.temporal.activity.Activity;
import io.temporal.failure.ApplicationFailure;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;

public class PublishActivitiesImpl implements PublishActivities {
  private static final HttpClient HTTP = HttpClient.newHttpClient();
  private static final ObjectMapper JSON = new ObjectMapper();

  @Override
  public String publishPost(String channel) {
    int attempt = Activity.getExecutionContext().getInfo().getAttempt();
    System.out.printf("Publishing to %s (attempt %d)%n", channel, attempt);
    try {
      HttpRequest request = HttpRequest.newBuilder(
              URI.create("http://localhost:9999/publish/" + channel))
          .timeout(Duration.ofSeconds(5))
          .header("content-type", "application/json")
          .POST(HttpRequest.BodyPublishers.ofString("{\"campaign\":\"summer-splash\"}"))
          .build();
      HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
      Map<String, Object> body = JSON.readValue(response.body(), new TypeReference<>() {});
      if (response.statusCode() >= 400 && response.statusCode() < 500) {
        throw ApplicationFailure.newNonRetryableFailure(
            channel + " rejected the post: " + body.get("error"),
            "ChannelPolicyError");
      }
      if (response.statusCode() < 200 || response.statusCode() >= 300) {
        throw new IllegalStateException(response.statusCode() + ": " + response.body());
      }
      return (String) body.get("placement_id");
    } catch (ApplicationFailure error) {
      throw error;
    } catch (Exception error) {
      throw new RuntimeException(error);
    }
  }
}
