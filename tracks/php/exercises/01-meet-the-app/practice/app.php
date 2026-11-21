<?php

/**
 * Launch the CatNip Cola "Summer Splash" campaign. What could go wrong?
 *
 * Run it:
 *   php exercises/01-meet-the-app/practice/app.php
 */

declare(strict_types=1);

const ADNET = 'http://localhost:9999';
const CHANNELS = ['meowta', 'catstagram', 'pettok'];

/** @return array<string, mixed> */
function post(string $path, array $body): array
{
    $curl = curl_init(ADNET . $path);
    curl_setopt_array($curl, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($body, JSON_THROW_ON_ERROR),
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 5,
    ]);
    $raw = curl_exec($curl);
    if ($raw === false) {
        throw new RuntimeException('AdNet unreachable: ' . curl_error($curl));
    }
    $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
    if ($status >= 300) {
        throw new RuntimeException("HTTP {$status}: {$raw}");
    }
    return json_decode((string) $raw, true, flags: JSON_THROW_ON_ERROR);
}

function validateCreative(string $campaign): string
{
    $body = post('/validate-creative', ['campaign' => $campaign]);
    echo "  ✅ Creative approved: {$body['creative_id']}\n";
    return $body['creative_id'];
}

function reserveBudget(string $campaign): string
{
    $body = post('/reserve-budget', ['campaign' => $campaign]);
    printf("  💸 Budget reserved: $%s (%s)\n", number_format($body['amount']), $body['reservation_id']);
    return $body['reservation_id'];
}

function publishToChannel(string $campaign, string $channel): string
{
    $body = post("/publish/{$channel}", ['campaign' => $campaign]);
    echo "  📣 Live on {$channel}: {$body['placement_id']}\n";
    return $body['placement_id'];
}

/** @param list<string> $placements */
function generateLaunchReport(
    string $campaign,
    string $creativeId,
    string $reservationId,
    array $placements,
): array {
    $report = [
        'campaign' => $campaign,
        'status' => 'LIVE',
        'creative_id' => $creativeId,
        'reservation_id' => $reservationId,
        'placements' => $placements,
        'channels_live' => count($placements),
    ];
    echo '  📊 Launch report: ' . json_encode($report, JSON_PRETTY_PRINT) . "\n";
    return $report;
}

function launchCampaign(string $campaign): array
{
    echo "🚀 Launching campaign '{$campaign}' for CatNip Cola...\n";
    $creativeId = validateCreative($campaign);
    sleep(1);
    $reservationId = reserveBudget($campaign);
    sleep(1);

    $placements = [];
    foreach (CHANNELS as $channel) {
        $placements[] = publishToChannel($campaign, $channel);
        sleep(1);
    }

    return generateLaunchReport($campaign, $creativeId, $reservationId, $placements);
}

launchCampaign('summer-splash');
