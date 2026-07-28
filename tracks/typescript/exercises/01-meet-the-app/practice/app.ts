/**
 * Launch the CatNip Cola "Summer Splash" campaign. What could go wrong?
 *
 * Run it:
 *   npx tsx exercises/01-meet-the-app/practice/app.ts
 */

const ADNET = 'http://localhost:9999';
const CHANNELS = ['meowta', 'catstagram', 'pettok'] as const;

type JsonObject = Record<string, unknown>;

interface LaunchReport {
  campaign: string;
  status: 'LIVE';
  creative_id: string;
  reservation_id: string;
  placements: string[];
  channels_live: number;
}

async function post(path: string, body: JsonObject): Promise<JsonObject> {
  const response = await fetch(`${ADNET}${path}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify(body),
    signal: AbortSignal.timeout(5_000),
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${await response.text()}`);
  }
  return (await response.json()) as JsonObject;
}

const pause = (milliseconds: number): Promise<void> =>
  new Promise((resolve) => setTimeout(resolve, milliseconds));

async function validateCreative(campaign: string): Promise<string> {
  const body = await post('/validate-creative', { campaign });
  const creativeId = body.creative_id as string;
  console.log(`  ✅ Creative approved: ${creativeId}`);
  return creativeId;
}

async function reserveBudget(campaign: string): Promise<string> {
  const body = await post('/reserve-budget', { campaign });
  console.log(
    `  💸 Budget reserved: $${(body.amount as number).toLocaleString('en-US')} (${body.reservation_id})`,
  );
  return body.reservation_id as string;
}

async function publishToChannel(campaign: string, channel: string): Promise<string> {
  const body = await post(`/publish/${channel}`, { campaign });
  const placementId = body.placement_id as string;
  console.log(`  📣 Live on ${channel}: ${placementId}`);
  return placementId;
}

function generateLaunchReport(
  campaign: string,
  creativeId: string,
  reservationId: string,
  placements: string[],
): LaunchReport {
  const report: LaunchReport = {
    campaign,
    status: 'LIVE',
    creative_id: creativeId,
    reservation_id: reservationId,
    placements,
    channels_live: placements.length,
  };
  console.log('  📊 Launch report:', report);
  return report;
}

async function launchCampaign(campaign: string): Promise<LaunchReport> {
  console.log(`🚀 Launching campaign '${campaign}' for CatNip Cola...`);
  const creativeId = await validateCreative(campaign);
  await pause(1_000);
  const reservationId = await reserveBudget(campaign);
  await pause(1_000);

  const placements: string[] = [];
  for (const channel of CHANNELS) {
    placements.push(await publishToChannel(campaign, channel));
    await pause(1_000);
  }

  return generateLaunchReport(campaign, creativeId, reservationId, placements);
}

launchCampaign('summer-splash').catch((error: unknown) => {
  console.error(error);
  process.exitCode = 1;
});
