package workshop;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.List;
import java.util.Map;

public class HashtagActivitiesImpl implements HashtagActivities {
  private static final HttpClient HTTP = HttpClient.newHttpClient();
  private static final ObjectMapper JSON = new ObjectMapper();

  @Override
  public List<String> fetchHashtags(String channel) {
    try {
      HttpRequest request = HttpRequest.newBuilder(
              URI.create("http://localhost:9999/trending/" + channel))
          .timeout(Duration.ofSeconds(5))
          .GET()
          .build();
      HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
      if (response.statusCode() != 200) throw new IllegalStateException(response.body());
      Map<String, Object> body = JSON.readValue(response.body(), new TypeReference<>() {});
      @SuppressWarnings("unchecked")
      List<String> hashtags = (List<String>) body.get("hashtags");
      return hashtags;
    } catch (Exception error) {
      throw new RuntimeException(error);
    }
  }
}
