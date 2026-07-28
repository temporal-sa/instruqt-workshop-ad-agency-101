package workshop;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.util.List;

public record LaunchReport(
    String campaign,
    String status,
    @JsonProperty("creative_id") String creativeId,
    @JsonProperty("reservation_id") String reservationId,
    List<String> placements,
    @JsonProperty("channels_live") int channelsLive) {}
