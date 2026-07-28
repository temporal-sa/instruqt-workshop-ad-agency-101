import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const { generateTagline, fetchHashtags } = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 seconds',
});

const BRAND = 'CatNip Cola';

export async function socialPostWorkflow(channel: string): Promise<string> {
  const tagline = await generateTagline(BRAND);
  const hashtags = await fetchHashtags(channel);
  return `${tagline} ${hashtags.join(' ')}`;
}
