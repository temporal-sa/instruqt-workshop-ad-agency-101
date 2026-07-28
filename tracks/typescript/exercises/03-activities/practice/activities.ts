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

// The worked example: an Activity is an ordinary async function.
// Activities contain fallible, non-deterministic work such as network I/O.
export async function generateTagline(brand: string): Promise<string> {
  const query = new URLSearchParams({ brand });
  const body = await getJson(`/tagline?${query}`);
  return body.tagline as string;
}

// TODO: Part B — export an async fetchHashtags Activity.
// It takes a channel name and returns Promise<string[]>.
// AdNet endpoint: GET http://localhost:9999/trending/<channel>
