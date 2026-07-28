package workshop;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Launch the CatNip Cola campaign as an ordinary, fragile Java process. */
public final class CampaignApp {
  private static final String ADNET = "http://localhost:9999";
  private static final List<String> CHANNELS = List.of("meowta", "catstagram", "pettok");
  private static final HttpClient HTTP = HttpClient.newHttpClient();
  private static final ObjectMapper JSON = new ObjectMapper();

  private CampaignApp() {}

  private static Map<String, Object> post(String path, Map<String, ?> input) throws Exception {
    HttpRequest request =
        HttpRequest.newBuilder(URI.create(ADNET + path))
            .timeout(Duration.ofSeconds(5))
            .header("content-type", "application/json")
            .POST(HttpRequest.BodyPublishers.ofString(JSON.writeValueAsString(input)))
            .build();
    HttpResponse<String> response = HTTP.send(request, HttpResponse.BodyHandlers.ofString());
    if (response.statusCode() < 200 || response.statusCode() >= 300) {
      throw new IllegalStateException(
          response.statusCode() + " from " + path + ": " + response.body());
    }
    return JSON.readValue(response.body(), new TypeReference<>() {});
  }

  private static String validateCreative(String campaign) throws Exception {
    String creativeId = (String) post("/validate-creative", Map.of("campaign", campaign))
        .get("creative_id");
    System.out.println("  ✅ Creative approved: " + creativeId);
    return creativeId;
  }

  private static String reserveBudget(String campaign) throws Exception {
    Map<String, Object> body = post("/reserve-budget", Map.of("campaign", campaign));
    System.out.printf("  💸 Budget reserved: $%,d (%s)%n", body.get("amount"), body.get("reservation_id"));
    return (String) body.get("reservation_id");
  }

  private static String publishToChannel(String campaign, String channel) throws Exception {
    String placementId =
        (String) post("/publish/" + channel, Map.of("campaign", campaign)).get("placement_id");
    System.out.println("  📣 Live on " + channel + ": " + placementId);
    return placementId;
  }

  private static Map<String, Object> launchCampaign(String campaign) throws Exception {
    System.out.println("🚀 Launching campaign '" + campaign + "' for CatNip Cola...");
    String creativeId = validateCreative(campaign);
    Thread.sleep(1_000);
    String reservationId = reserveBudget(campaign);
    Thread.sleep(1_000);
    List<String> placements = new ArrayList<>();
    for (String channel : CHANNELS) {
      placements.add(publishToChannel(campaign, channel));
      Thread.sleep(1_000);
    }
    Map<String, Object> report = new LinkedHashMap<>();
    report.put("campaign", campaign);
    report.put("status", "LIVE");
    report.put("creative_id", creativeId);
    report.put("reservation_id", reservationId);
    report.put("placements", placements);
    report.put("channels_live", placements.size());
    System.out.println("  📊 Launch report: " + report);
    return report;
  }

  public static void main(String[] args) throws Exception {
    launchCampaign("summer-splash");
  }
}
