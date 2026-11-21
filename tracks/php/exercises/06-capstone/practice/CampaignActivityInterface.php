<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityInterface;
use Temporal\Activity\ActivityMethod;

// These are the same four operations from exercise 1.
//
// TODO: Part B — mark this interface as an Activity contract so a Worker can
// register its implementation. Use the prefix "Campaign." so the Activity
// Types become Campaign.validateCreative, Campaign.reserveBudget, ...
interface CampaignActivityInterface
{
    #[ActivityMethod]
    public function validateCreative(string $campaign): string;

    #[ActivityMethod]
    public function reserveBudget(string $campaign): string;

    #[ActivityMethod]
    public function publishToChannel(string $campaign, string $channel): string;

    /** @param list<string> $placements */
    #[ActivityMethod]
    public function generateLaunchReport(
        string $campaign,
        string $creativeId,
        string $reservationId,
        array $placements,
    ): array;
}
