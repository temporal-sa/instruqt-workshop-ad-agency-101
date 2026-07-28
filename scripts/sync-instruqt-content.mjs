#!/usr/bin/env node

/**
 * Make a language track's local exercise READMEs the source of truth for the
 * matching Instruqt assignment bodies. Challenge frontmatter, tabs, and
 * lifecycle scripts remain owned by the Instruqt directory.
 *
 * Usage:
 *   node scripts/sync-instruqt-content.mjs typescript java
 */

import { readFile, writeFile } from 'node:fs/promises';
import { basename, join, resolve } from 'node:path';

const root = resolve(import.meta.dirname, '..');
const languages = process.argv.slice(2);

if (languages.length === 0) {
  throw new Error('Pass one or more track directories: python, typescript, java');
}

for (const language of languages) {
  const trackRoot = join(root, 'tracks', language);
  const exerciseRoot = join(trackRoot, 'exercises');
  const instruqtRoot = join(trackRoot, 'instruqt');

  for (const challenge of [
    '01-meet-the-app',
    '02-first-workflow',
    '03-activities',
    '04-retries-and-errors',
    '05-human-in-the-loop',
    '06-capstone',
    '07-bonus-observability',
    '08-to-the-cloud',
  ]) {
    const readmePath = join(exerciseRoot, challenge, 'README.md');
    const assignmentPath = join(instruqtRoot, challenge, 'assignment.md');
    const [readme, assignment] = await Promise.all([
      readFile(readmePath, 'utf8'),
      readFile(assignmentPath, 'utf8'),
    ]);

    const match = assignment.match(/^---\n([\s\S]*?)\n---\n/);
    if (!match) {
      throw new Error(`Missing YAML frontmatter: ${assignmentPath}`);
    }

    const heading =
      readme.match(/^# (.+)$/m)?.[1] ?? basename(challenge).replaceAll('-', ' ');
    const goal =
      readme.match(/^\*\*Goal:\*\*\s*([\s\S]*?)(?:\n\n|\n#)/m)?.[1]
        .replaceAll('\n', ' ')
        .trim() ?? 'Complete the exercise using the language-specific SDK.';

    const frontmatter = match[1].replace(
      /notes:\n[\s\S]*?\ntabs:/,
      `notes:\n- type: text\n  contents: |-\n    # ${heading}\n    ${goal}\ntabs:`,
    );

    await writeFile(assignmentPath, `---\n${frontmatter}\n---\n\n${readme}`);
  }
}
