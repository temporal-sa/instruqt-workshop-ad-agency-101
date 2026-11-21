<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityInterface;
use Temporal\Activity\ActivityMethod;

// The Activity Type is prefix + method name: Hashtag.fetchHashtags
#[ActivityInterface(prefix: 'Hashtag.')]
interface HashtagActivityInterface
{
    /** @return list<string> */
    #[ActivityMethod]
    public function fetchHashtags(string $channel): array;
}
