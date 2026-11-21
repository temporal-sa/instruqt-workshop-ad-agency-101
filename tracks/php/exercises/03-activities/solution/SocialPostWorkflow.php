<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityOptions;
use Temporal\Internal\Workflow\ActivityProxy;
use Temporal\Workflow;
use Temporal\Workflow\WorkflowInterface;
use Temporal\Workflow\WorkflowMethod;

#[WorkflowInterface]
final class SocialPostWorkflow
{
    private const BRAND = 'CatNip Cola';

    private ActivityProxy|TaglineActivityInterface $taglineActivities;
    private ActivityProxy|HashtagActivityInterface $hashtagActivities;

    public function __construct()
    {
        $options = ActivityOptions::new()->withStartToCloseTimeout(10);
        $this->taglineActivities = Workflow::newActivityStub(TaglineActivityInterface::class, $options);
        $this->hashtagActivities = Workflow::newActivityStub(HashtagActivityInterface::class, $options);
    }

    #[WorkflowMethod]
    public function run(string $channel): \Generator
    {
        $tagline = yield $this->taglineActivities->generateTagline(self::BRAND);
        $hashtags = yield $this->hashtagActivities->fetchHashtags($channel);
        return $tagline . ' ' . implode(' ', $hashtags);
    }
}
