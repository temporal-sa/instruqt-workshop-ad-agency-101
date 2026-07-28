import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const { publishPost } = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 seconds',
  retry: {
    initialInterval: '1 second',
    backoffCoefficient: 2,
    maximumInterval: '10 seconds',
  },
});

export async function publishWorkflow(channel: string): Promise<string> {
  return await publishPost(channel);
}
