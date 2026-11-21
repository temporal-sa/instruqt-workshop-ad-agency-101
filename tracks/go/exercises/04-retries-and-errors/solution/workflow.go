package publish

import (
	"time"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

var publishActivities *PublishActivities

func PublishWorkflow(ctx workflow.Context, channel string) (string, error) {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Second,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:    time.Second,
			BackoffCoefficient: 2,
			MaximumInterval:    10 * time.Second,
		},
	})

	var placementID string
	err := workflow.ExecuteActivity(ctx, publishActivities.PublishPost, channel).Get(ctx, &placementID)
	return placementID, err
}
