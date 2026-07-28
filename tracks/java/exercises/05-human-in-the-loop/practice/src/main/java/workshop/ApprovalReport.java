package workshop;

import com.fasterxml.jackson.annotation.JsonProperty;

public record ApprovalReport(
    String campaign,
    String status,
    @JsonProperty("approved_by") String approvedBy,
    @JsonProperty("next_step") String nextStep) {}
