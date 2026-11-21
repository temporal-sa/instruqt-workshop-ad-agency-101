<?php

/**
 * Replay the capstone history against your current Workflow code.
 *
 * First export:
 *   temporal workflow show -w campaign-summer-splash -o json \
 *     > exercises/07-bonus-observability/history.json
 * Then:
 *   php exercises/07-bonus-observability/replay.php
 *
 * The PHP SDK replays through RoadRunner: this script starts a short-lived
 * RoadRunner replay host (see .rr.yaml and replay-worker.php), sends it the
 * history over RPC, and stops it again.
 */

declare(strict_types=1);

use Symfony\Component\Process\Process;
use Temporal\Testing\Replay\WorkflowReplayer;

require __DIR__ . '/../../vendor/autoload.php';

$history = __DIR__ . '/history.json';
if (!is_file($history)) {
    fwrite(STDERR, "history.json not found. Export it first:\n"
        . "  temporal workflow show -w campaign-summer-splash -o json"
        . " > exercises/07-bonus-observability/history.json\n");
    exit(1);
}

$roadRunner = new Process(['rr', 'serve', '-c', __DIR__ . '/.rr.yaml'], timeout: null);
$roadRunner->start();

$exitCode = 0;
try {
    $started = false;
    for ($i = 0; $i < 100 && $roadRunner->isRunning(); $i++) {
        if (str_contains($roadRunner->getOutput() . $roadRunner->getErrorOutput(), 'RoadRunner server started')) {
            $started = true;
            break;
        }
        usleep(200_000);
    }
    if (!$started) {
        throw new RuntimeException("RoadRunner replay host did not start:\n"
            . $roadRunner->getOutput() . $roadRunner->getErrorOutput());
    }

    $_SERVER['RR_RPC'] = 'tcp://127.0.0.1:6002';
    (new WorkflowReplayer())->replayFromJSON('CampaignWorkflow', realpath($history));
    echo "Replay OK: your Workflow code is compatible with the recorded history.\n";
} catch (Throwable $e) {
    fwrite(STDERR, get_class($e) . ': ' . $e->getMessage() . "\n");
    $exitCode = 1;
} finally {
    $roadRunner->stop(5);
}
exit($exitCode);
