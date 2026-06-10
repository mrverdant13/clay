import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

test('mustache tag body regex rejects empty tags', () => {
  const source = readFileSync(
    join(extensionRoot, 'src/mustacheHighlighting.ts'),
    'utf8',
  );
  const patternMatch = source.match(
    /export const MUSTACHE_TAG_PATTERN = String\.raw`([^`]+)`;/,
  );
  assert.ok(patternMatch, 'MUSTACHE_TAG_PATTERN not found');

  const replaceMatch = source.match(
    /MUSTACHE_TAG_PATTERN\.replace\('([^']+)', '([^']+)'\)/,
  );
  assert.ok(replaceMatch, 'MUSTACHE_TAG_BODY_REGEX replace not found');

  const regex = new RegExp(
    patternMatch[1].replace(replaceMatch[1], replaceMatch[2]),
    'g',
  );

  assert.equal('{{}}'.match(regex), null);
  assert.match('{{#foo}}', regex);
});
