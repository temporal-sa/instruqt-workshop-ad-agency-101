const ADNET = 'http://localhost:9999';

async function getJson(path: string): Promise<Record<string, unknown>> {
  const response = await fetch(`${ADNET}${path}`, {
    signal: AbortSignal.timeout(5_000),
  });
  if (!response.ok) {
    throw new Error(`${response.status} ${response.statusText}: ${await response.text()}`);
  }
  return (await response.json()) as Record<string, unknown>;
}

export async function generateTagline(brand: string): Promise<string> {
  const query = new URLSearchParams({ brand });
  const body = await getJson(`/tagline?${query}`);
  return body.tagline as string;
}

export async function fetchHashtags(channel: string): Promise<string[]> {
  const body = await getJson(`/trending/${channel}`);
  return body.hashtags as string[];
}
