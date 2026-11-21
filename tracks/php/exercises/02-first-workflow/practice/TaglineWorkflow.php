<?php

declare(strict_types=1);

namespace Workshop;

use Temporal\Workflow;
use Temporal\Workflow\WorkflowInterface;
use Temporal\Workflow\WorkflowMethod;

// The Workflow Type defaults to the class name: TaglineWorkflow.
#[WorkflowInterface]
final class TaglineWorkflow
{
    #[WorkflowMethod]
    public function run(string $brand): string
    {
        Workflow::getLogger()->info('Generating tagline', ['brand' => $brand]);
        // TODO: Part B — return the tagline: the brand name, a colon and a
        // space, then "Taste the Meow!"  e.g.  "CatNip Cola: Taste the Meow!"
        return 'TODO';
    }
}
