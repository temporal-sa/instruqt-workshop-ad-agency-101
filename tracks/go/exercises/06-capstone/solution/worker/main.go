// Run it:
//
//	go run ./exercises/06-capstone/solution/worker
package main

import (
	"log"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	campaign "workshop/exercises/06-capstone/solution"
)

func main() {
	c, err := client.Dial(client.Options{})
	if err != nil {
		log.Fatalln("Unable to connect to Temporal:", err)
	}
	defer c.Close()

	w := worker.New(c, "campaign-tasks", worker.Options{})
	w.RegisterWorkflow(campaign.CampaignWorkflow)
	w.RegisterActivity(&campaign.CampaignActivities{})

	log.Println("Worker started on task queue 'campaign-tasks'. Ctrl-C to stop.")
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalln("Worker stopped:", err)
	}
}
