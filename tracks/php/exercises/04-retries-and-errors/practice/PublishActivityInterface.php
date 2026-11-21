<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityInterface;
use Temporal\Activity\ActivityMethod;

// The Activity Type is prefix + method name: Publish.publishPost
#[ActivityInterface(prefix: 'Publish.')]
interface PublishActivityInterface
{
    #[ActivityMethod]
    public function publishPost(string $channel): string;
}
