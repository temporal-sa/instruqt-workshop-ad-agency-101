package approval

import (
	"time"

	"go.temporal.io/sdk/workflow"
)

// ApproveSignal is the Signal name the CLI sends.
const ApproveSignal = "approve"

type ApprovalReport struct {
	Campaign   string  `json:"campaign"`
	Status     string  `json:"status"` // APPROVED or EXPIRED
	ApprovedBy *string `json:"approved_by"`
	NextStep   string  `json:"next_step"`
}

func CampaignApprovalWorkflow(ctx workflow.Context, campaign string, approvalDeadlineSeconds int) (ApprovalReport, error) {
	var approvedBy string

	// Signals arrive on a channel. This Workflow goroutine waits for one.
	approveCh := workflow.GetSignalChannel(ctx, ApproveSignal)
	workflow.Go(ctx, func(ctx workflow.Context) {
		approveCh.Receive(ctx, &approvedBy)
	})

	workflow.GetLogger(ctx).Info("Campaign awaiting client approval",
		"campaign", campaign, "approvalDeadlineSeconds", approvalDeadlineSeconds)

	received, err := workflow.AwaitWithTimeout(ctx,
		time.Duration(approvalDeadlineSeconds)*time.Second,
		func() bool { return approvedBy != "" })
	if err != nil {
		return ApprovalReport{}, err
	}

	if !received {
		return ApprovalReport{
			Campaign:   campaign,
			Status:     "EXPIRED",
			ApprovedBy: nil,
			NextStep:   "escalate to the account exec (by fax, probably)",
		}, nil
	}
	return ApprovalReport{
		Campaign:   campaign,
		Status:     "APPROVED",
		ApprovedBy: &approvedBy,
		NextStep:   "cleared for launch",
	}, nil
}
