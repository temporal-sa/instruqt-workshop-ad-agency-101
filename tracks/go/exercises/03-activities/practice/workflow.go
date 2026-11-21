package social

import (
	"strings"
	"time"

	"go.temporal.io/sdk/workflow"
)

const brand = "CatNip Cola"

// Nil pointers are enough: the Workflow only uses them to name the
// Activity methods; the Worker runs the registered implementations.
var (
	taglineActivities *TaglineActivities
	hashtagActivities *HashtagActivities
)

func SocialPostWorkflow(ctx workflow.Context, channel string) (string, error) {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		StartToCloseTimeout: 10 * time.Second,
	})

	var tagline string
	err := workflow.ExecuteActivity(ctx, taglineActivities.GenerateTagline, brand).Get(ctx, &tagline)
	if err != nil {
		return "", err
	}

	// TODO: Part C — schedule FetchHashtags through the same typed method
	// reference pattern used for GenerateTagline above:
	//
	//   var hashtags []string
	//   err = workflow.ExecuteActivity(ctx, hashtagActivities.FetchHashtags, channel).Get(ctx, &hashtags)
	//
	// ExecuteActivity schedules an Activity Task; it does not call the
	// networked implementation inside the Workflow.
	hashtags := []string{}
	return tagline + " " + strings.Join(hashtags, " "), nil
}
