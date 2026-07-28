package workshop;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;

final class AdNetClient {
  private static final HttpClient HTTP = HttpClient.newHttpClient();
  private static final ObjectMapper JSON = new ObjectMapper();

  record Response(int status, Map<String, Object> body) {}

  private AdNetClient() {}

  static Response post(String path, String campaign) {
    try {
      HttpRequest request =
          HttpRequest.newBuilder(URI.create("http://localhost:9999" + path))
              .timeout(Duration.ofSeconds(5))
              .header("content-type", "application/json")
              .POST(
                  HttpRequest.BodyPublishers.ofString(
                      JSON.writeValueAsString(Map.of("campaign", campaign))))
              .build();
      HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
      return new Response(
          response.statusCode(),
          JSON.readValue(response.body(), new TypeReference<>() {}));
    } catch (Exception error) {
      throw new RuntimeException(error);
    }
  }
}
