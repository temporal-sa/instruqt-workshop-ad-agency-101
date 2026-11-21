<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityOptions;
use Temporal\Common\RetryOptions;
use Temporal\Internal\Workflow\ActivityProxy;
use Temporal\Workflow;
use Temporal\Workflow\WorkflowInterface;
use Temporal\Workflow\WorkflowMethod;

#[WorkflowInterface]
final class CampaignWorkflow
{
    private const CHANNELS = ['meowta', 'catstagram', 'pettok'];

    private ActivityProxy|CampaignActivityInterface $activities;
    private ActivityProxy|CampaignActivityInterface $publishing;

    public function __construct()
    {
        $this->activities = Workflow::newActivityStub(
            CampaignActivityInterface::class,
            ActivityOptions::new()->withStartToCloseTimeout(10),
        );
        $this->publishing = Workflow::newActivityStub(
            CampaignActivityInterface::class,
            ActivityOptions::new()
                ->withStartToCloseTimeout(10)
                ->withRetryOptions(
                    RetryOptions::new()
                        ->withInitialInterval(1)
                        ->withBackoffCoefficient(2)
                        ->withMaximumInterval(10),
                ),
        );
    }

    #[WorkflowMethod]
    public function run(string $campaign): \Generator
    {
        $creativeId = yield $this->activities->validateCreative($campaign);
        $reservationId = yield $this->activities->reserveBudget($campaign);

        $placements = [];
        foreach (self::CHANNELS as $channel) {
            $placements[] = yield $this->publishing->publishToChannel($campaign, $channel);
        }

        return yield $this->activities->generateLaunchReport(
            $campaign,
            $creativeId,
            $reservationId,
            $placements,
        );
    }
}
