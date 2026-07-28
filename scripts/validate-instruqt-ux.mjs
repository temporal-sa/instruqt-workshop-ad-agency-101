#!/usr/bin/env node

import { readFile } from 'node:fs/promises';
import { join, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const languages = ['typescript', 'java'];
const challenges = [
  '01-meet-the-app',
  '02-first-workflow',
  '03-activities',
  '04-retries-and-errors',
  '05-human-in-the-loop',
  '06-capstone',
  '07-bonus-observability',
  '08-to-the-cloud',
];
const persistentTabs = new Map([
  ['Server', 'server'],
  ['AdNet', 'adnet'],
  ['Worker', 'worker'],
  ['CLI', 'cli'],
]);
const tabIndexes = new Map([
  ['Editor', 0],
  ['Server', 1],
  ['AdNet', 2],
  ['Worker', 3],
  ['CLI', 4],
  ['Temporal UI', 5],
  ['Download', 6],
]);

const failures = [];

function fail(path, message) {
  failures.push(`${path}: ${message}`);
}

function expectedCommandTab(command) {
  if (command.includes('temporal server start-dev')) {
    return 'Server';
  }
  if (command.includes('services/adnet.py')) {
    return 'AdNet';
  }
  if (
    command.includes('/worker.ts') ||
    /-Dexec\.mainClass=workshop\.\w*Worker/.test(command)
  ) {
    return 'Worker';
  }
  return 'CLI';
}

for (const language of languages) {
  for (const challenge of challenges) {
    const readmePath = join(
      root,
      'tracks',
      language,
      'exercises',
      challenge,
      'README.md',
    );
    const assignmentPath = join(
      root,
      'tracks',
      language,
      'instruqt',
      challenge,
      'assignment.md',
    );
    const [readme, assignment] = await Promise.all([
      readFile(readmePath, 'utf8'),
      readFile(assignmentPath, 'utf8'),
    ]);
    const assignmentMatch = assignment.match(/^---\n[\s\S]*?\n---\n\n([\s\S]*)$/);

    if (!assignmentMatch) {
      fail(assignmentPath, 'missing assignment frontmatter or body');
      continue;
    }
    if (assignmentMatch[1].trimEnd() !== readme.trimEnd()) {
      fail(assignmentPath, 'body is out of sync with its exercise README');
    }

    const tabBlocks =
      assignment.match(/^- id:[\s\S]*?(?=^- id:|^difficulty:)/gm) ?? [];
    for (const [title, session] of persistentTabs) {
      const block = tabBlocks.find((candidate) =>
        candidate.includes(`  title: ${title}\n`),
      );
      if (!block) {
        fail(assignmentPath, `missing ${title} terminal tab`);
        continue;
      }
      const expected = `  cmd: tmux new-session -A -s ${session}`;
      if (!block.includes(expected)) {
        fail(
          assignmentPath,
          `${title} must reattach the persistent "${session}" tmux session`,
        );
      }
    }

    const body = assignmentMatch[1];
    const tabLinkPattern =
      /\[button label="([^"]+)"\]\(tab-([0-9]+)\)/g;
    const links = [...body.matchAll(tabLinkPattern)];
    if (links.length === 0) {
      fail(assignmentPath, 'has no clickable Instruqt tab links');
    }
    for (const link of links) {
      const expectedIndex = tabIndexes.get(link[1]);
      if (expectedIndex === undefined) {
        fail(assignmentPath, `uses unknown tab label "${link[1]}"`);
      } else if (Number(link[2]) !== expectedIndex) {
        fail(
          assignmentPath,
          `${link[1]} points to tab-${link[2]}, expected tab-${expectedIndex}`,
        );
      }
    }

    const runnableBlocks = [
      ...body.matchAll(/^```bash,run\n([\s\S]*?)^```$/gm),
    ];
    if (runnableBlocks.length === 0) {
      fail(assignmentPath, 'has no runnable command blocks');
    }
    for (const block of runnableBlocks) {
      const preceding = body.slice(0, block.index);
      const precedingLinks = [...preceding.matchAll(tabLinkPattern)];
      const lastLink = precedingLinks.at(-1);
      if (!lastLink) {
        fail(assignmentPath, 'runnable command has no preceding tab link');
        continue;
      }
      const expectedTab = expectedCommandTab(block[1]);
      if (lastLink[1] !== expectedTab) {
        fail(
          assignmentPath,
          `command expected in ${expectedTab}, but the preceding link opens ${lastLink[1]}`,
        );
      }
    }

    const plainBashBlocks = [...body.matchAll(/^```bash\n([\s\S]*?)^```$/gm)];
    const allowedPlainBlocks = challenge === '08-to-the-cloud' ? 1 : 0;
    if (plainBashBlocks.length !== allowedPlainBlocks) {
      fail(
        assignmentPath,
        `has ${plainBashBlocks.length} non-runnable bash blocks; expected ${allowedPlainBlocks}`,
      );
    }

    if (challenge === '01-meet-the-app') {
      if (
        !body.includes(
          'temporal server start-dev --ip 0.0.0.0 --ui-ip 0.0.0.0',
        )
      ) {
        fail(assignmentPath, 'does not start the externally reachable dev server');
      }
      if (!body.includes('.adnet-venv/bin/python services/adnet.py')) {
        fail(assignmentPath, 'does not start AdNet');
      }
    }
  }
}

if (failures.length > 0) {
  console.error('Instruqt interaction validation failed:');
  for (const failure of failures) {
    console.error(`- ${failure}`);
  }
  process.exit(1);
}

console.log('Instruqt tab links, run controls, and tmux attachments are valid.');
