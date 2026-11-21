<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityInterface;
use Temporal\Activity\ActivityMethod;

// Activity Types are prefix + method name, for example Campaign.reserveBudget
#[ActivityInterface(prefix: 'Campaign.')]
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
