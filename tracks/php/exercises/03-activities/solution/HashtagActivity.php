<?php

declare(strict_types=1);

namespace Workshop;

final class HashtagActivity implements HashtagActivityInterface
{
    public function fetchHashtags(string $channel): array
    {
        $body = AdNetClient::getJson("/trending/{$channel}");
        return $body['hashtags'];
    }
}
