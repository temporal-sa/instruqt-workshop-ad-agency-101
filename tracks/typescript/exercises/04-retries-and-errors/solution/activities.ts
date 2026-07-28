import { activityInfo } from '@temporalio/activity';
import { ApplicationFailure } from '@temporalio/common';

const ADNET = 'http://localhost:9999';

export async function publishPost(channel: string): Promise<string> {
  console.log(`Publishing to ${channel} (attempt ${activityInfo().attempt})`);
  const response = await fetch(`${ADNET}/publish/${channel}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ campaign: 'summer-splash' }),
    signal: AbortSignal.timeout(5_000),
  });
  if (response.status >= 400 && response.status < 500) {
    const detail = (await response.json()) as { error?: string };
    throw ApplicationFailure.nonRetryable(
      `${channel} rejected the post: ${detail.error ?? response.statusText}`,
      'ChannelPolicyError',
    );
  }
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${await response.text()}`);
  }
  const body = (await response.json()) as { placement_id: string };
  return body.placement_id;
}
