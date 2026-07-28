import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const CHANNELS = ['meowta', 'catstagram', 'pettok'] as const;

export async function campaignWorkflow(
  campaign: string,
): Promise<Record<string, unknown>> {
  // This used to be launchCampaign() in app.ts:
  //
  // const creativeId = await validateCreative(campaign);
  // const reservationId = await reserveBudget(campaign);
  // const placements = [];
  // for (const channel of CHANNELS) {
  //   placements.push(await publishToChannel(campaign, channel));
  // }
  // return generateLaunchReport(campaign, creativeId, reservationId, placements);
  //
  // TODO: Part C — create typed Activity proxies with
  // proxyActivities<typeof activities>(). Give every Activity a 10-second
  // start-to-close timeout. Give the publishing proxy a retry policy whose
  // nonRetryableErrorTypes includes "ChannelPolicyError", then rebuild the
  // sequence above by awaiting each proxy call.
  void proxyActivities;
  void CHANNELS;
  throw new Error('Part C');
}
