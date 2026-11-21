<?php

declare(strict_types=1);

namespace Workshop;

/** A tiny JSON-over-HTTP client for the AdNet mock service. */
final class AdNetClient
{
    private const BASE_URL = 'http://localhost:9999';

    /**
     * POST a JSON body and return the HTTP status with the decoded response.
     *
     * @return array{int, array<string, mixed>}
     */
    public static function post(string $path, array $payload): array
    {
        $curl = curl_init(self::BASE_URL . $path);
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
