// Run it:
//
//	go run ./exercises/03-activities/solution/worker
package main

import (
	"log"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	social "workshop/exercises/03-activities/solution"
)

func main() {
	c, err := client.Dial(client.Options{})
	if err != nil {
		log.Fatalln("Unable to connect to Temporal:", err)
	}
	defer c.Close()

	w := worker.New(c, "social-tasks", worker.Options{})
	w.RegisterWorkflow(social.SocialPostWorkflow)
	w.RegisterActivity(&social.TaglineActivities{})
	w.RegisterActivity(&social.HashtagActivities{})

	log.Println("Worker started on task queue 'social-tasks'. Ctrl-C to stop.")
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalln("Worker stopped:", err)
	}
}
