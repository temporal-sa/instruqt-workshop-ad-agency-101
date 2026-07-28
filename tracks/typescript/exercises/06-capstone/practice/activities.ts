import { activityInfo } from '@temporalio/activity';
import { ApplicationFailure } from '@temporalio/common';

const ADNET = 'http://localhost:9999';

interface LaunchReport {
  campaign: string;
  status: 'LIVE';
  creative_id: string;
  reservation_id: string;
  placements: string[];
  channels_live: number;
}

async function postJson(
  path: string,
  body: Record<string, unknown>,
): Promise<{ response: Response; body: Record<string, unknown> }> {
  const response = await fetch(`${ADNET}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(5_000),
  });
  const parsed = (await response.json()) as Record<string, unknown>;
  return { response, body: parsed };
}

// These are the same four operations from exercise 1. In TypeScript an
// Activity implementation is simply an exported async function.
//
// TODO: Part B — export all four functions so a Worker can register them.
// TODO: Part D — in publishToChannel, turn 4xx into a non-retryable
// ApplicationFailure with type "ChannelPolicyError".

async function validateCreative(campaign: string): Promise<string> {
  const { response, body } = await postJson('/validate-creative', { campaign });
  if (!response.ok) throw new Error(`${response.status}: ${JSON.stringify(body)}`);
  return body.creative_id as string;
}

async function reserveBudget(campaign: string): Promise<string> {
  const { response, body } = await postJson('/reserve-budget', { campaign });
  if (!response.ok) throw new Error(`${response.status}: ${JSON.stringify(body)}`);
  return body.reservation_id as string;
}

async function publishToChannel(campaign: string, channel: string): Promise<string> {
  console.log(`Publishing to ${channel} (attempt ${activityInfo().attempt})`);
  const { response, body } = await postJson(`/publish/${channel}`, { campaign });
  // TODO: Part D — fail fast on response.status >= 400 && response.status < 500.
  void ApplicationFailure;
  if (!response.ok) throw new Error(`${response.status}: ${JSON.stringify(body)}`);
  return body.placement_id as string;
}

async function generateLaunchReport(
  campaign: string,
  creativeId: string,
  reservationId: string,
  placements: string[],
): Promise<LaunchReport> {
  return {
    campaign,
    status: 'LIVE',
    creative_id: creativeId,
    reservation_id: reservationId,
    placements,
    channels_live: placements.length,
  };
}

void validateCreative;
void reserveBudget;
void publishToChannel;
void generateLaunchReport;
