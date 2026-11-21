// Run it:
//
//	go run ./exercises/04-retries-and-errors/practice/worker
package main

import (
	"log"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	publish "workshop/exercises/04-retries-and-errors/practice"
)

func main() {
	c, err := client.Dial(client.Options{})
	if err != nil {
		log.Fatalln("Unable to connect to Temporal:", err)
	}
	defer c.Close()

	w := worker.New(c, "publish-tasks", worker.Options{})
	w.RegisterWorkflow(publish.PublishWorkflow)
	w.RegisterActivity(&publish.PublishActivities{})

	log.Println("Worker started on task queue 'publish-tasks'. Ctrl-C to stop.")
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalln("Worker stopped:", err)
	}
}
