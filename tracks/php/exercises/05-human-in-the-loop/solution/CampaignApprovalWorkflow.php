<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Workflow;
use Temporal\Workflow\SignalMethod;
use Temporal\Workflow\WorkflowInterface;
use Temporal\Workflow\WorkflowMethod;

#[WorkflowInterface]
final class CampaignApprovalWorkflow
{
    private ?string $approvedBy = null;

    // The Signal name defaults to the method name: approve
    #[SignalMethod]
    public function approve(string $approver): void
    {
        $this->approvedBy = $approver;
    }

    #[WorkflowMethod]
    public function run(string $campaign, int $approvalDeadlineSeconds)
    {
        Workflow::getLogger()->info('Campaign awaiting client approval', [
            'campaign' => $campaign,
            'approvalDeadlineSeconds' => $approvalDeadlineSeconds,
        ]);

        $received = yield Workflow::awaitWithTimeout(
            $approvalDeadlineSeconds,
            fn(): bool => $this->approvedBy !== null,
        );

        if (!$received) {
            return [
                'campaign' => $campaign,
                'status' => 'EXPIRED',
                'approved_by' => null,
                'next_step' => 'escalate to the account exec (by fax, probably)',
            ];
        }
        return [
            'campaign' => $campaign,
            'status' => 'APPROVED',
            'approved_by' => $this->approvedBy,
            'next_step' => 'cleared for launch',
        ];
    }
}
