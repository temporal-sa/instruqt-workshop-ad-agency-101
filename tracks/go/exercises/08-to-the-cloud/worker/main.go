// The same Worker as exercise 2, connected to Temporal Cloud.
// Workflow code and Task Queue configuration are unchanged.
//
// Run it:
//
//	go run ./exercises/08-to-the-cloud/worker
package main

import (
	"crypto/tls"
	"log"
	"os"
	"strings"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/worker"

	cloud "workshop/exercises/08-to-the-cloud"
)

func main() {
	var missing []string
	for _, name := range []string{"TEMPORAL_ADDRESS", "TEMPORAL_NAMESPACE", "TEMPORAL_API_KEY"} {
		if os.Getenv(name) == "" {
			missing = append(missing, name)
		}
	}
	if len(missing) > 0 {
		log.Fatalf("Set %s first — see this exercise's README.", strings.Join(missing, ", "))
	}

	namespace := os.Getenv("TEMPORAL_NAMESPACE")
	c, err := client.Dial(client.Options{
		HostPort:    os.Getenv("TEMPORAL_ADDRESS"),
		Namespace:   namespace,
		Credentials: client.NewAPIKeyStaticCredentials(os.Getenv("TEMPORAL_API_KEY")),
		ConnectionOptions: client.ConnectionOptions{
			TLS: &tls.Config{},
		},
	})
	if err != nil {
		log.Fatalln("Unable to connect to Temporal Cloud:", err)
	}
	defer c.Close()

	w := worker.New(c, "tagline-tasks", worker.Options{})
	w.RegisterWorkflow(cloud.TaglineWorkflow)

	log.Printf("Worker connected to %s on Temporal Cloud. Ctrl-C to stop.", namespace)
	if err := w.Run(worker.InterruptCh()); err != nil {
		log.Fatalln("Worker stopped:", err)
	}
}
