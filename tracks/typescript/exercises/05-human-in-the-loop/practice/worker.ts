import { Worker } from '@temporalio/worker';

async function main(): Promise<void> {
  const worker = await Worker.create({
    workflowsPath: require.resolve('./workflows'),
    taskQueue: 'approval-tasks',
  });
  console.log("Worker started on task queue 'approval-tasks'. Ctrl-C to stop.");
  await worker.run();
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
