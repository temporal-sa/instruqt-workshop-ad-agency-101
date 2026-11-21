package campaign

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"go.temporal.io/sdk/activity"
	"go.temporal.io/sdk/temporal"
)

const adnet = "http://localhost:9999"

var httpClient = &http.Client{Timeout: 5 * time.Second}

type LaunchReport struct {
	Campaign      string   `json:"campaign"`
	Status        string   `json:"status"`
	CreativeID    string   `json:"creative_id"`
	ReservationID string   `json:"reservation_id"`
	Placements    []string `json:"placements"`
	ChannelsLive  int      `json:"channels_live"`
}

// postJSON returns the HTTP status and raw response body.
func postJSON(ctx context.Context, path, campaign string) (int, []byte, error) {
	payload, _ := json.Marshal(map[string]string{"campaign": campaign})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, adnet+path, bytes.NewReader(payload))
	if err != nil {
		return 0, nil, err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := httpClient.Do(req)
	if err != nil {
		return 0, nil, err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	return resp.StatusCode, body, err
}

// field decodes one string field from a successful response; any other
// status is an ordinary, retryable error.
func field(status int, body []byte, name string) (string, error) {
	if status < 200 || status >= 300 {
		return "", fmt.Errorf("%d: %s", status, body)
	}
	var decoded map[string]any
	if err := json.Unmarshal(body, &decoded); err != nil {
		return "", err
	}
	value, _ := decoded[name].(string)
	return value, nil
}

type CampaignActivities struct{}

// These are the same four operations from exercise 1, now exported
// methods on CampaignActivities that take context.Context first.

func (a *CampaignActivities) ValidateCreative(ctx context.Context, campaign string) (string, error) {
	status, body, err := postJSON(ctx, "/validate-creative", campaign)
	if err != nil {
		return "", err
	}
	return field(status, body, "creative_id")
}

func (a *CampaignActivities) ReserveBudget(ctx context.Context, campaign string) (string, error) {
	status, body, err := postJSON(ctx, "/reserve-budget", campaign)
	if err != nil {
		return "", err
	}
	return field(status, body, "reservation_id")
}

func (a *CampaignActivities) PublishToChannel(ctx context.Context, campaign, channel string) (string, error) {
	activity.GetLogger(ctx).Info("Publishing", "channel", channel, "attempt", activity.GetInfo(ctx).Attempt)
	status, body, err := postJSON(ctx, "/publish/"+channel, campaign)
	if err != nil {
		return "", err
	}
	if status >= 400 && status < 500 {
		return "", temporal.NewNonRetryableApplicationError(
			fmt.Sprintf("%s rejected the campaign: %s", channel, body),
			"ChannelPolicyError",
			nil,
		)
	}
	return field(status, body, "placement_id")
}

func (a *CampaignActivities) GenerateLaunchReport(ctx context.Context, campaign, creativeID, reservationID string, placements []string) (LaunchReport, error) {
	return LaunchReport{
		Campaign:      campaign,
		Status:        "LIVE",
		CreativeID:    creativeID,
		ReservationID: reservationID,
		Placements:    placements,
		ChannelsLive:  len(placements),
	}, nil
}
