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

  // TODO: Part D — 4xx is a permanent business failure. Detect it and:
  //
  // throw ApplicationFailure.nonRetryable(
  //   'human-readable message',
  //   'ChannelPolicyError',
  // );
  void ApplicationFailure; // Keeps the teaching import live until the TODO is completed.

  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${await response.text()}`);
  }
  const body = (await response.json()) as { placement_id: string };
  return body.placement_id;
}
