<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Activity\ActivityOptions;
use Temporal\Common\RetryOptions;
use Temporal\Internal\Workflow\ActivityProxy;
use Temporal\Workflow;
use Temporal\Workflow\WorkflowInterface;
use Temporal\Workflow\WorkflowMethod;

#[WorkflowInterface]
final class PublishWorkflow
{
    private ActivityProxy|PublishActivityInterface $activities;

    public function __construct()
    {
        $this->activities = Workflow::newActivityStub(
            PublishActivityInterface::class,
            ActivityOptions::new()
                ->withStartToCloseTimeout(10)
                ->withRetryOptions(
                    RetryOptions::new()
                        ->withInitialInterval(1)
                        ->withBackoffCoefficient(2)
                        ->withMaximumInterval(10),
                ),
        );
    }

    #[WorkflowMethod]
    public function run(string $channel): \Generator
    {
        return yield $this->activities->publishPost($channel);
    }
}
