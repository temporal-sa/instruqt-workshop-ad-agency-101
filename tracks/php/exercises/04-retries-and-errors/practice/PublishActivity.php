<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity;
use Temporal\Exception\Failure\ApplicationFailure;

final class PublishActivity implements PublishActivityInterface
{
    private const ADNET = 'http://localhost:9999';

    public function publishPost(string $channel): string
    {
        // Worker output goes to STDERR: STDOUT belongs to RoadRunner.
        fwrite(STDERR, sprintf("Publishing to %s (attempt %d)\n", $channel, Activity::getInfo()->attempt));
        [$status, $body] = $this->post("/publish/{$channel}", ['campaign' => 'summer-splash']);

        // TODO: Part D — 4xx is a permanent business failure. Detect it
        // ($status >= 400 && $status < 500) and throw:
        //
        // throw new ApplicationFailure(
        //     message: "{$channel} rejected the post: " . json_encode($body),
        //     type: 'ChannelPolicyError',
        //     nonRetryable: true,
        // );
        if ($status >= 300) {
            throw new \RuntimeException("HTTP {$status}: " . json_encode($body));
        }
        return $body['placement_id'];
    }

    /** @return array{int, array<string, mixed>} */
    private function post(string $path, array $payload): array
    {
        $curl = curl_init(self::ADNET . $path);
        curl_setopt_array($curl, [
            CURLOPT_POST => true,
            CURLOPT_POSTFIELDS => json_encode($payload, JSON_THROW_ON_ERROR),
            CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 5,
        ]);
        $raw = curl_exec($curl);
        if ($raw === false) {
            throw new \RuntimeException('AdNet unreachable: ' . curl_error($curl));
        }
        $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
        return [$status, json_decode((string) $raw, true) ?? []];
    }
}
