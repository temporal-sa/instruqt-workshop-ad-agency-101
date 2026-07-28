import { Worker } from '@temporalio/worker';
import { generateTagline } from './activities';

async function main(): Promise<void> {
  const worker = await Worker.create({
    workflowsPath: require.resolve('./workflows'),
    activities: { generateTagline }, // TODO: Part D — register fetchHashtags too
    taskQueue: 'social-tasks',
  });
  console.log("Worker started on task queue 'social-tasks'. Ctrl-C to stop.");
  await worker.run();
}

main().catch((error: unknown) => {
  console.error(error);
  process.exit(1);
});
