<?php

declare(strict_types=1);

namespace Workshop;

// The worked example: an Activity implementation is an ordinary PHP class.
// Activities contain fallible, non-deterministic work such as network I/O.
final class TaglineActivity implements TaglineActivityInterface
{
    public function generateTagline(string $brand): string
    {
        $body = AdNetClient::getJson('/tagline?' . http_build_query(['brand' => $brand]));
        return $body['tagline'];
    }
}
