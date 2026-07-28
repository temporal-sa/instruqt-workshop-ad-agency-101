/**
 * The same Worker as exercise 2, connected to Temporal Cloud.
 * Workflow code and Task Queue configuration are unchanged.
 */

import { NativeConnection, Worker } from '@temporalio/worker';

const REQUIRED = [
  'TEMPORAL_ADDRESS',
  'TEMPORAL_NAMESPACE',
  'TEMPORAL_API_KEY',
] as const;

async function main(): Promise<void> {
  const missing = REQUIRED.filter((name) => !process.env[name]);
  if (missing.length > 0) {
    throw new Error(`Set ${missing.join(', ')} first — see this exercise's README.`);
  }

  const address = process.env.TEMPORAL_ADDRESS as string;
  const namespace = process.env.TEMPORAL_NAMESPACE as string;
  const apiKey = process.env.TEMPORAL_API_KEY as string;
  const connection = await NativeConnection.connect({
    address,
    tls: true,
    apiKey,
  });

  try {
    const worker = await Worker.create({
      connection,
      namespace,
      workflowsPath: require.resolve('./workflows'),
      taskQueue: 'tagline-tasks',
    });
    console.log(
      `Worker connected to ${namespace} on Temporal Cloud. Ctrl-C to stop.`,
    );
    await worker.run();
  } finally {
    await connection.close();
  }
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
