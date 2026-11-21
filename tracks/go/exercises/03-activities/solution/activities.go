package social

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/url"
	"time"
)

const adnet = "http://localhost:9999"

var httpClient = &http.Client{Timeout: 5 * time.Second}

func getJSON(ctx context.Context, path string, out any) error {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, adnet+path, nil)
	if err != nil {
		return err
	}
	resp, err := httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusOK {
		return fmt.Errorf("GET %s: %s", path, resp.Status)
	}
	return json.NewDecoder(resp.Body).Decode(out)
}

// TaglineActivities is the worked example. Activities are ordinary Go
// methods that take context.Context first; they may do network I/O.
type TaglineActivities struct{}

func (a *TaglineActivities) GenerateTagline(ctx context.Context, brand string) (string, error) {
	var body struct {
		Tagline string `json:"tagline"`
	}
	if err := getJSON(ctx, "/tagline?brand="+url.QueryEscape(brand), &body); err != nil {
		return "", err
	}
	return body.Tagline, nil
}

// HashtagActivities fetches trending hashtags for a channel from AdNet.
type HashtagActivities struct{}

func (a *HashtagActivities) FetchHashtags(ctx context.Context, channel string) ([]string, error) {
	var body struct {
		Hashtags []string `json:"hashtags"`
	}
	if err := getJSON(ctx, "/trending/"+channel, &body); err != nil {
		return nil, err
	}
	return body.Hashtags, nil
}
