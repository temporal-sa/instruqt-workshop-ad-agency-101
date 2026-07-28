import { proxyActivities } from '@temporalio/workflow';
import type * as activities from './activities';

const { generateTagline } = proxyActivities<typeof activities>({
  startToCloseTimeout: '10 seconds',
});

const BRAND = 'CatNip Cola';

export async function socialPostWorkflow(channel: string): Promise<string> {
  const tagline = await generateTagline(BRAND);
  // TODO: Part C — include fetchHashtags in the proxy above, then await it
  // for `channel`. The proxy schedules an Activity; it does not call the
  // implementation directly inside the Workflow sandbox.
  const hashtags: string[] = [];
  return `${tagline} ${hashtags.join(' ')}`;
}
