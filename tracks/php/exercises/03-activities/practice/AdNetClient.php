<?php

declare(strict_types=1);

namespace Workshop;

/** A tiny JSON-over-HTTP client for the AdNet mock service. */
final class AdNetClient
{
    private const BASE_URL = 'http://localhost:9999';

    /** @return array<string, mixed> */
    public static function getJson(string $path): array
    {
        $curl = curl_init(self::BASE_URL . $path);
        curl_setopt_array($curl, [CURLOPT_RETURNTRANSFER => true, CURLOPT_TIMEOUT => 5]);
        $raw = curl_exec($curl);
        if ($raw === false) {
            throw new \RuntimeException('AdNet unreachable: ' . curl_error($curl));
        }
        $status = curl_getinfo($curl, CURLINFO_RESPONSE_CODE);
        if ($status >= 300) {
            throw new \RuntimeException("HTTP {$status}: {$raw}");
        }
        return json_decode((string) $raw, true, flags: JSON_THROW_ON_ERROR);
    }
}
