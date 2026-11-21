<?php

/**
 * RoadRunner starts this script; do not run it with php directly:
 *   rr serve -o server.command="php exercises/02-first-workflow/practice/worker.php"
 */

declare(strict_types=1);

use Temporal\WorkerFactory;
use Workshop\TaglineWorkflow;

require __DIR__ . '/../../../vendor/autoload.php';
require_once __DIR__ . '/TaglineWorkflow.php';

$factory = WorkerFactory::create();

$worker = $factory->newWorker('TODO'); // TODO: Part C — the starter command targets "tagline-tasks"
$worker->registerWorkflowTypes(TaglineWorkflow::class);

$factory->run();
