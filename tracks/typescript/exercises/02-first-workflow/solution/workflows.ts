import { log } from '@temporalio/workflow';

export async function taglineWorkflow(brand: string): Promise<string> {
  log.info('Generating tagline', { brand });
  return `${brand}: Taste the Meow!`;
}
