<?php

/**
 * RoadRunner starts this script; do not run it with php directly:
 *   rr serve -o server.command="php exercises/05-human-in-the-loop/practice/worker.php"
 */

declare(strict_types=1);

use Temporal\WorkerFactory;
use Workshop\CampaignApprovalWorkflow;

require __DIR__ . '/../../../vendor/autoload.php';
require_once __DIR__ . '/CampaignApprovalWorkflow.php';

$factory = WorkerFactory::create();

$worker = $factory->newWorker('approval-tasks');
$worker->registerWorkflowTypes(CampaignApprovalWorkflow::class);

$factory->run();
