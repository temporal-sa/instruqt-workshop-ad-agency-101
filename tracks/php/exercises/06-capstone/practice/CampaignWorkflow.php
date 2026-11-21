<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityOptions;
use Temporal\Common\RetryOptions;
use Temporal\Exception\Failure\ApplicationFailure;
use Temporal\Internal\Workflow\ActivityProxy;
use Temporal\Workflow;
use Temporal\Workflow\WorkflowInterface;
use Temporal\Workflow\WorkflowMethod;

#[WorkflowInterface]
final class CampaignWorkflow
{
    private const CHANNELS = ['meowta', 'catstagram', 'pettok'];

    // TODO: Part C — declare two typed stubs, for example:
    // private ActivityProxy|CampaignActivityInterface $activities;
    // private ActivityProxy|CampaignActivityInterface $publishing;
    //
    // Create both in a constructor with Workflow::newActivityStub() and a
    // 10-second start-to-close timeout. Give the publishing stub
    // RetryOptions: 1-second initial interval, backoff coefficient 2,
    // 10-second maximum interval.

    #[WorkflowMethod]
    public function run(string $campaign): \Generator
    {
        // This used to be launchCampaign() in app.php:
        //
        // $creativeId = validateCreative($campaign);
        // $reservationId = reserveBudget($campaign);
        // $placements = [];
        // foreach (CHANNELS as $channel) {
        //     $placements[] = publishToChannel($campaign, $channel);
        // }
        // return generateLaunchReport($campaign, $creativeId, $reservationId, $placements);
        //
        // TODO: Part C — rebuild the sequence above with the stubs. Each stub
        // call returns a promise: `yield` it to get the Activity result.
        throw new ApplicationFailure('Complete Part C', 'IncompleteExercise', true);
    }
}
