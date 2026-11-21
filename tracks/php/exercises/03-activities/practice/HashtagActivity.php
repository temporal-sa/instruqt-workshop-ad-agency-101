<?php

declare(strict_types=1);

namespace Workshop;

final class HashtagActivity implements HashtagActivityInterface
{
    public function fetchHashtags(string $channel): array
    {
        // TODO: Part B — fetch GET /trending/<channel> from AdNet and return
        // the decoded "hashtags" list:
        //
        // $body = AdNetClient::getJson("/trending/{$channel}");
        // return $body['hashtags'];
        return [];
    }
}
