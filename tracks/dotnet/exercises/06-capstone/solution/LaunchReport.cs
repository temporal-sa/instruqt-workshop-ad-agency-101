using System.Text.Json.Serialization;

namespace Workshop;

public record LaunchReport(
    [property: JsonPropertyName("campaign")] string Campaign,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("creative_id")] string CreativeId,
    [property: JsonPropertyName("reservation_id")] string ReservationId,
    [property: JsonPropertyName("placements")] List<string> Placements,
    [property: JsonPropertyName("channels_live")] int ChannelsLive);
