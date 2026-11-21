<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity;
use Temporal\Exception\Failure\ApplicationFailure;

final class CampaignActivity implements CampaignActivityInterface
{
    public function validateCreative(string $campaign): string
    {
        [$status, $body] = AdNetClient::post('/validate-creative', ['campaign' => $campaign]);
        if ($status >= 300) {
            throw new \RuntimeException("HTTP {$status}: " . json_encode($body));
        }
        return $body['creative_id'];
    }

    public function reserveBudget(string $campaign): string
    {
        [$status, $body] = AdNetClient::post('/reserve-budget', ['campaign' => $campaign]);
        if ($status >= 300) {
            throw new \RuntimeException("HTTP {$status}: " . json_encode($body));
        }
        return $body['reservation_id'];
    }

    public function publishToChannel(string $campaign, string $channel): string
    {
        // Worker output goes to STDERR: STDOUT belongs to RoadRunner.
        fwrite(STDERR, sprintf("Publishing to %s (attempt %d)\n", $channel, Activity::getInfo()->attempt));
        [$status, $body] = AdNetClient::post("/publish/{$channel}", ['campaign' => $campaign]);
        if ($status >= 400 && $status < 500) {
            throw new ApplicationFailure(
                message: "{$channel} rejected the campaign: " . json_encode($body),
                type: 'ChannelPolicyError',
                nonRetryable: true,
            );
        }
        if ($status >= 300) {
            throw new \RuntimeException("HTTP {$status}: " . json_encode($body));
        }
        return $body['placement_id'];
    }

    public function generateLaunchReport(
        string $campaign,
        string $creativeId,
        string $reservationId,
        array $placements,
    ): array {
        return [
            'campaign' => $campaign,
            'status' => 'LIVE',
            'creative_id' => $creativeId,
            'reservation_id' => $reservationId,
            'placements' => $placements,
            'channels_live' => count($placements),
        ];
    }
}
