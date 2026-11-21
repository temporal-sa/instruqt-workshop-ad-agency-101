// Replay the capstone history against the learner's current Workflow code.
//
// First export:
//
//	temporal workflow show -w campaign-summer-splash -o json \
//	  > exercises/07-bonus-observability/history.json
//
// Then, from the workshop root:
//
//	go run ./exercises/07-bonus-observability/replay
package main

import (
	"errors"
	"fmt"
	"log"
	"os"

	"go.temporal.io/sdk/worker"

	campaign "workshop/exercises/06-capstone/practice"
)

const historyPath = "exercises/07-bonus-observability/history.json"

func main() {
	if _, err := os.Stat(historyPath); errors.Is(err, os.ErrNotExist) {
		log.Fatalln("history.json not found. Export it first:\n" +
			"  temporal workflow show -w campaign-summer-splash -o json " +
			"> exercises/07-bonus-observability/history.json")
	}

	replayer := worker.NewWorkflowReplayer()
	replayer.RegisterWorkflow(campaign.CampaignWorkflow)
	if err := replayer.ReplayWorkflowHistoryFromJSONFile(nil, historyPath); err != nil {
		log.Fatalln("Replay failed:", err)
	}
	fmt.Println("Replay OK: your Workflow code is compatible with the recorded history.")
}
