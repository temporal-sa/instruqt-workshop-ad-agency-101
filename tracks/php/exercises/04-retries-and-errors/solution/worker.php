<?php

/**
 * RoadRunner starts this script; do not run it with php directly:
 *   rr serve -o server.command="php exercises/04-retries-and-errors/practice/worker.php"
 */

declare(strict_types=1);

use Temporal\WorkerFactory;
use Workshop\PublishActivity;
use Workshop\PublishWorkflow;

require __DIR__ . '/../../../vendor/autoload.php';
require_once __DIR__ . '/PublishActivityInterface.php';
require_once __DIR__ . '/PublishActivity.php';
require_once __DIR__ . '/PublishWorkflow.php';

$factory = WorkerFactory::create();

$worker = $factory->newWorker('publish-tasks');
$worker->registerWorkflowTypes(PublishWorkflow::class);
$worker->registerActivity(PublishActivity::class);

$factory->run();
