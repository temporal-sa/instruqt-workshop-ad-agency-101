<?php

/**
 * RoadRunner starts this script; do not run it with php directly:
 *   rr serve -o server.command="php exercises/06-capstone/practice/worker.php"
 */

declare(strict_types=1);

use Temporal\WorkerFactory;
use Workshop\CampaignActivity;
use Workshop\CampaignWorkflow;

require __DIR__ . '/../../../vendor/autoload.php';
require_once __DIR__ . '/AdNetClient.php';
require_once __DIR__ . '/CampaignActivityInterface.php';
require_once __DIR__ . '/CampaignActivity.php';
require_once __DIR__ . '/CampaignWorkflow.php';

$factory = WorkerFactory::create();

$worker = $factory->newWorker('campaign-tasks');
// TODO: Part E — register CampaignWorkflow::class with registerWorkflowTypes()
// TODO: Part E — register CampaignActivity::class with registerActivity()

$factory->run();
