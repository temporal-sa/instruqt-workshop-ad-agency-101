using System.Text.Json.Serialization;

namespace Workshop;

public record ApprovalReport(
    [property: JsonPropertyName("campaign")] string Campaign,
    [property: JsonPropertyName("status")] string Status,
    [property: JsonPropertyName("approved_by")] string? ApprovedBy,
    [property: JsonPropertyName("next_step")] string NextStep);
