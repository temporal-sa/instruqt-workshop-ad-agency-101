import { log } from '@temporalio/workflow';

export async function taglineWorkflow(brand: string): Promise<string> {
  log.info('Generating tagline', { brand });
  // TODO: Part B — return the tagline: the brand name, a colon and a space,
  // then "Taste the Meow!"  e.g.  "CatNip Cola: Taste the Meow!"
  return 'TODO';
}
