package campaign

import (
	"time"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

var channels = []string{"meowta", "catstagram", "pettok"}

func CampaignWorkflow(ctx workflow.Context, campaign string) (LaunchReport, error) {
	var a *CampaignActivities

	defaultCtx := workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Second,
	})
	publishCtx := workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Second,
		RetryPolicy: &temporal.RetryPolicy{
			InitialInterval:        time.Second,
			BackoffCoefficient:     2,
			MaximumInterval:        10 * time.Second,
			NonRetryableErrorTypes: []string{"ChannelPolicyError"},
		},
	})

	var creativeID string
	if err := workflow.ExecuteActivity(defaultCtx, a.ValidateCreative, campaign).Get(ctx, &creativeID); err != nil {
		return LaunchReport{}, err
	}
	var reservationID string
	if err := workflow.ExecuteActivity(defaultCtx, a.ReserveBudget, campaign).Get(ctx, &reservationID); err != nil {
		return LaunchReport{}, err
	}

	placements := make([]string, 0, len(channels))
	for _, channel := range channels {
		var placementID string
		if err := workflow.ExecuteActivity(publishCtx, a.PublishToChannel, campaign, channel).Get(ctx, &placementID); err != nil {
			return LaunchReport{}, err
		}
		placements = append(placements, placementID)
	}

	var report LaunchReport
	err := workflow.ExecuteActivity(defaultCtx, a.GenerateLaunchReport, campaign, creativeID, reservationID, placements).Get(ctx, &report)
	return report, err
}
