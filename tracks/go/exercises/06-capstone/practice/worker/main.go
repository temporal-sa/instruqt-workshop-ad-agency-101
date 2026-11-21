// Run it:
//
//	go run ./exercises/06-capstone/practice/worker
package main

import (
	"log"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	campaign "workshop/exercises/06-capstone/practice"
)

func main() {
	c, err := client.Dial(client.Options{})
	if err != nil {
		log.Fatalln("Unable to connect to Temporal:", err)
	}
	defer c.Close()

	w := worker.New(c, "campaign-tasks", worker.Options{})
	// TODO: Part E — register campaign.CampaignWorkflow and
	// &campaign.CampaignActivities{} with w.RegisterWorkflow and
	// w.RegisterActivity.
	_ = campaign.CampaignWorkflow

	log.Println("Worker started on task queue 'campaign-tasks'. Ctrl-C to stop.")
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalln("Worker stopped:", err)
	}
}
