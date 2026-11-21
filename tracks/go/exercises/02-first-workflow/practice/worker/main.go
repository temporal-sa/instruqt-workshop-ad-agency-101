// Run it:
//
//	go run ./exercises/02-first-workflow/practice/worker
package main

import (
	"log"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	tagline "workshop/exercises/02-first-workflow/practice"
)

func main() {
	c, err := client.Dial(client.Options{})
	if err != nil {
		log.Fatalln("Unable to connect to Temporal:", err)
	}
	defer c.Close()

	taskQueue := "TODO" // TODO: Part C — the starter command targets "tagline-tasks"
	w := worker.New(c, taskQueue, worker.Options{})
	w.RegisterWorkflow(tagline.TaglineWorkflow)

	log.Println("Worker started on task queue 'tagline-tasks'. Ctrl-C to stop.")
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalln("Worker stopped:", err)
	}
}
