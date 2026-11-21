<?php

/**
 * The same Worker as exercise 2, connected to Temporal Cloud.
 * Workflow code and Task Queue configuration are unchanged.
 *
 * RoadRunner starts this script with the settings in rr.yaml:
 *   rr serve -c exercises/08-to-the-cloud/rr.yaml
 */

declare(strict_types=1);

use Temporal\Worker\ServiceCredentials;
use Temporal\WorkerFactory;
use Workshop\TaglineWorkflow;

require __DIR__ . '/../../vendor/autoload.php';
require_once __DIR__ . '/TaglineWorkflow.php';

$required = ['TEMPORAL_ADDRESS', 'TEMPORAL_NAMESPACE', 'TEMPORAL_API_KEY'];
$missing = array_values(array_filter($required, static fn(string $name): bool => (string) getenv($name) === ''));
if ($missing !== []) {
    fwrite(STDERR, 'Set ' . implode(', ', $missing) . " first — see this exercise's README.\n");
    exit(1);
}

// RoadRunner owns the connection; the PHP SDK passes it the API key.
$factory = WorkerFactory::create(
    credentials: ServiceCredentials::create()->withApiKey((string) getenv('TEMPORAL_API_KEY')),
);

$worker = $factory->newWorker('tagline-tasks');
$worker->registerWorkflowTypes(TaglineWorkflow::class);

$factory->run();
