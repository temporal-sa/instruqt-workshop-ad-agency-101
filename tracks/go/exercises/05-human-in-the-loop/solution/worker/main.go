// Run it:
//
//	go run ./exercises/05-human-in-the-loop/solution/worker
package main

import (
	"log"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	approval "workshop/exercises/05-human-in-the-loop/solution"
)

func main() {
	c, err := client.Dial(client.Options{})
	if err != nil {
		log.Fatalln("Unable to connect to Temporal:", err)
	}
	defer c.Close()

	w := worker.New(c, "approval-tasks", worker.Options{})
	w.RegisterWorkflow(approval.CampaignApprovalWorkflow)

	log.Println("Worker started on task queue 'approval-tasks'. Ctrl-C to stop.")
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalln("Worker stopped:", err)
	}
}
