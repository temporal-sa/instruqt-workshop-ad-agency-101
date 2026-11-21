<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityInterface;
use Temporal\Activity\ActivityMethod;

// The Activity Type is prefix + method name: Tagline.generateTagline
#[ActivityInterface(prefix: 'Tagline.')]
interface TaglineActivityInterface
{
    #[ActivityMethod]
    public function generateTagline(string $brand): string;
}
