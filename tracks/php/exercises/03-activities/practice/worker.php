<?php

/**
 * RoadRunner starts this script; do not run it with php directly:
 *   rr serve -o server.command="php exercises/03-activities/practice/worker.php"
 */

declare(strict_types=1);

use Temporal\WorkerFactory;
use Workshop\HashtagActivity;
use Workshop\SocialPostWorkflow;
use Workshop\TaglineActivity;

require __DIR__ . '/../../../vendor/autoload.php';
require_once __DIR__ . '/AdNetClient.php';
require_once __DIR__ . '/TaglineActivityInterface.php';
require_once __DIR__ . '/TaglineActivity.php';
require_once __DIR__ . '/HashtagActivityInterface.php';
require_once __DIR__ . '/HashtagActivity.php';
require_once __DIR__ . '/SocialPostWorkflow.php';

$factory = WorkerFactory::create();

$worker = $factory->newWorker('social-tasks');
$worker->registerWorkflowTypes(SocialPostWorkflow::class);
$worker->registerActivity(TaglineActivity::class);
// TODO: Part D — register HashtagActivity::class too

$factory->run();
