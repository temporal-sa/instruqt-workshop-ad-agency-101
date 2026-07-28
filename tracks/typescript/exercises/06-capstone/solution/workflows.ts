import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const defaultActivities = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 seconds',
});
const publishingActivities = proxyActivities<
  Pick<typeof activities, 'publishToChannel'>
>({
  startToCloseTimeout: '10 seconds',
  retry: {
    initialInterval: '1 second',
    backoffCoefficient: 2,
    maximumInterval: '10 seconds',
    nonRetryableErrorTypes: ['ChannelPolicyError'],
  },
});

const CHANNELS = ['meowta', 'catstagram', 'pettok'] as const;

export async function campaignWorkflow(
  campaign: string,
): Promise<activities.LaunchReport> {
  const creativeId = await defaultActivities.validateCreative(campaign);
  const reservationId = await defaultActivities.reserveBudget(campaign);
  const placements: string[] = [];
  for (const channel of CHANNELS) {
    placements.push(
      await publishingActivities.publishToChannel(campaign, channel),
    );
  }
  return await defaultActivities.generateLaunchReport(
    campaign,
    creativeId,
    reservationId,
    placements,
  );
}
