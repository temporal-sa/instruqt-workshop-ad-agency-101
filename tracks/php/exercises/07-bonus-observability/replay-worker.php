<?php

/**
 * The PHP side of the replay host. RoadRunner replays Workflow histories
 * against the Workflow classes this script registers: your capstone practice
 * code. The Task Queue must match the recorded history.
 */

declare(strict_types=1);

use Temporal\WorkerFactory;
use Workshop\CampaignWorkflow;

$capstone = __DIR__ . '/../06-capstone/practice';

require __DIR__ . '/../../vendor/autoload.php';
require_once $capstone . '/CampaignActivityInterface.php';
require_once $capstone . '/CampaignWorkflow.php';

$factory = WorkerFactory::create();
$factory->newWorker('campaign-tasks')->registerWorkflowTypes(CampaignWorkflow::class);
$factory->run();
