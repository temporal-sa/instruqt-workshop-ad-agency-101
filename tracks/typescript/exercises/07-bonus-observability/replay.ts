/**
 * Replay the capstone history against the learner's current Workflow code.
 *
 * First export:
 *   temporal workflow show -w campaign-summer-splash -o json \
 *     > exercises/07-bonus-observability/history.json
 * Then:
 *   npx tsx exercises/07-bonus-observability/replay.ts
 */

import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { Worker } from '@temporalio/worker';

async function main(): Promise<void> {
  const historyPath = resolve(__dirname, 'history.json');
  let history: unknown;
  try {
    history = JSON.parse(await readFile(historyPath, 'utf8'));
  } catch (error: unknown) {
    if ((error as NodeJS.ErrnoException).code === 'ENOENT') {
      throw new Error(
        'history.json not found. Export it first:\n' +
          '  temporal workflow show -w campaign-summer-splash -o json ' +
          '> exercises/07-bonus-observability/history.json',
      );
    }
    throw error;
  }

  await Worker.runReplayHistory(
    {
      workflowsPath: require.resolve(
        '../06-capstone/practice/workflows',
      ),
    },
    history as never,
  );
  console.log(
    'Replay OK: your Workflow code is compatible with the recorded history.',
  );
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
