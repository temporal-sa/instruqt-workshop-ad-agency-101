package campaign

import (
	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

var channels = []string{"meowta", "catstagram", "pettok"}

func CampaignWorkflow(ctx workflow.Context, campaign string) (LaunchReport, error) {
	// This used to be launchCampaign() in exercise 1:
	//
	//   creativeID, err := validateCreative(campaign)
	//   reservationID, err := reserveBudget(campaign)
	//   var placements []string
	//   for _, channel := range channels {
	//       placementID, err := publishToChannel(campaign, channel)
	//       placements = append(placements, placementID)
	//   }
	//   return generateLaunchReport(campaign, creativeID, reservationID, placements)
	//
	// TODO: Part C — derive two Activity contexts with
	// workflow.WithActivityOptions. Give every Activity a 10-second
	// StartToCloseTimeout. Give the publishing context a RetryPolicy whose
	// NonRetryableErrorTypes includes "ChannelPolicyError". Then rebuild the
	// sequence above with workflow.ExecuteActivity(ctx, a.Method, args...).Get(ctx, &result),
	// where a is a nil *CampaignActivities.
	_ = channels
	return LaunchReport{}, temporal.NewApplicationError("Complete Part C", "IncompleteExercise")
}
