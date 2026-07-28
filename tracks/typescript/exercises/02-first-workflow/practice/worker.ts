import { Worker } from '@temporalio/worker';

async function main(): Promise<void> {
  const worker = await Worker.create({
    workflowsPath: require.resolve('./workflows'),
    taskQueue: 'TODO', // TODO: Part C — the starter command targets "tagline-tasks"
  });
  console.log("Worker started on task queue 'tagline-tasks'. Ctrl-C to stop.");
  await worker.run();
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
