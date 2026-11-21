// Launch the CatNip Cola "Summer Splash" campaign. What could go wrong?
//
// Run it:
//
//	go run ./exercises/01-meet-the-app/practice
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"
)

const adnet = "http://localhost:9999"

var channels = []string{"meowta", "catstagram", "pettok"}

var httpClient = &http.Client{Timeout: 5 * time.Second}

type LaunchReport struct {
	Campaign      string   `json:"campaign"`
	Status        string   `json:"status"`
	CreativeID    string   `json:"creative_id"`
	ReservationID string   `json:"reservation_id"`
	Placements    []string `json:"placements"`
	ChannelsLive  int      `json:"channels_live"`
}

func post(path string, campaign string, out any) error {
	payload, err := json.Marshal(map[string]string{"campaign": campaign})
	if err != nil {
		return err
	}
	resp, err := httpClient.Post(adnet+path, "application/json", bytes.NewReader(payload))
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("POST %s: %s: %s", path, resp.Status, body)
	}
	return json.Unmarshal(body, out)
}

func validateCreative(campaign string) (string, error) {
	var body struct {
		CreativeID string `json:"creative_id"`
	}
	if err := post("/validate-creative", campaign, &body); err != nil {
		return "", err
	}
	fmt.Printf("  ✅ Creative approved: %s\n", body.CreativeID)
	return body.CreativeID, nil
}

func reserveBudget(campaign string) (string, error) {
	var body struct {
		ReservationID string `json:"reservation_id"`
		Amount        int    `json:"amount"`
	}
	if err := post("/reserve-budget", campaign, &body); err != nil {
		return "", err
	}
	fmt.Printf("  💸 Budget reserved: $%d (%s)\n", body.Amount, body.ReservationID)
	return body.ReservationID, nil
}

func publishToChannel(campaign, channel string) (string, error) {
	var body struct {
		PlacementID string `json:"placement_id"`
	}
	if err := post("/publish/"+channel, campaign, &body); err != nil {
		return "", err
	}
	fmt.Printf("  📣 Live on %s: %s\n", channel, body.PlacementID)
	return body.PlacementID, nil
}

func generateLaunchReport(campaign, creativeID, reservationID string, placements []string) LaunchReport {
	report := LaunchReport{
		Campaign:      campaign,
		Status:        "LIVE",
		CreativeID:    creativeID,
		ReservationID: reservationID,
		Placements:    placements,
		ChannelsLive:  len(placements),
	}
	fmt.Printf("  📊 Launch report: %+v\n", report)
	return report
}

func launchCampaign(campaign string) (LaunchReport, error) {
	fmt.Printf("🚀 Launching campaign '%s' for CatNip Cola...\n", campaign)
	creativeID, err := validateCreative(campaign)
	if err != nil {
		return LaunchReport{}, err
	}
	time.Sleep(time.Second)
	reservationID, err := reserveBudget(campaign)
	if err != nil {
		return LaunchReport{}, err
	}
	time.Sleep(time.Second)

	// This slice lives only in this process's memory.
	var placements []string
	for _, channel := range channels {
		placementID, err := publishToChannel(campaign, channel)
		if err != nil {
			return LaunchReport{}, err
		}
		placements = append(placements, placementID)
		time.Sleep(time.Second)
	}

	return generateLaunchReport(campaign, creativeID, reservationID, placements), nil
}

func main() {
	if _, err := launchCampaign("summer-splash"); err != nil {
		log.Fatalf("💥 launch crashed: %v", err)
	}
}
