package publish

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

type PublishActivities struct{}

func (a *PublishActivities) PublishPost(ctx context.Context, channel string) (string, error) {
	activity.GetLogger(ctx).Info("Publishing", "channel", channel, "attempt", activity.GetInfo(ctx).Attempt)

	payload, _ := json.Marshal(map[string]string{"campaign": "summer-splash"})
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, adnet+"/publish/"+channel, bytes.NewReader(payload))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := httpClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", err
	}

	if resp.StatusCode >= 400 && resp.StatusCode < 500 {
		return "", temporal.NewNonRetryableApplicationError(
			fmt.Sprintf("%s rejected the post: %s", channel, body),
			"ChannelPolicyError",
			nil,
		)
	}

	// Any other error is an ordinary, retryable Activity failure.
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return "", fmt.Errorf("%s: %s", resp.Status, body)
	}
	var result struct {
		PlacementID string `json:"placement_id"`
	}
	if err := json.Unmarshal(body, &result); err != nil {
		return "", err
	}
	return result.PlacementID, nil
}
