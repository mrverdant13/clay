import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);

const {
  findPairedBlockSpans,
  findPairedBlockInteriors,
  findNamedPairedBlockSpans,
  findNamedPairedBlockInteriors,
} = require('./out/annotationBlockPairing.cjs');

const {
  REMOVE_MARKER_SETS,
  REPLACE_MARKER_SETS,
  PARTIAL_MARKER_SETS,
} = require('./out/annotationMarkerSets.cjs');

test('findPairedBlockSpans pairs remove blocks', () => {
  const text = 'before /*remove-start*/ drop /*remove-end*/ after';
  const spans = findPairedBlockSpans(text, REMOVE_MARKER_SETS.slice(0, 1));

  assert.equal(spans.length, 1);
  assert.equal(text.slice(spans[0].start, spans[0].end), '/*remove-start*/ drop /*remove-end*/');
});

test('findPairedBlockInteriors excludes marker text', () => {
  const text = '/*remove-start*/interior/*remove-end*/';
  const interiors = findPairedBlockInteriors(text, REMOVE_MARKER_SETS.slice(0, 1));

  assert.equal(interiors.length, 1);
  assert.equal(text.slice(interiors[0].start, interiors[0].end), 'interior');
});

test('findNamedPairedBlockSpans matches partial names', () => {
  const text = '/*partial v foo*/body/*partial ^ foo*/';
  const spans = findNamedPairedBlockSpans(text, PARTIAL_MARKER_SETS.slice(0, 1));

  assert.equal(spans.length, 1);
  assert.equal(text.slice(spans[0].start, spans[0].end), text.trim());
});

test('findNamedPairedBlockSpans ignores incidental whitespace in partial names', () => {
  const text = '/*partial v foo */body/*partial ^ foo*/';
  const spans = findNamedPairedBlockSpans(text, PARTIAL_MARKER_SETS.slice(0, 1));

  assert.equal(spans.length, 1);
  assert.equal(text.slice(spans[0].start, spans[0].end), text.trim());
});

test('findNamedPairedBlockSpans survives mismatched end markers', () => {
  const text = '/*partial v foo*/body/*partial ^ bar*/more/*partial ^ foo*/';
  const spans = findNamedPairedBlockSpans(text, PARTIAL_MARKER_SETS.slice(0, 1));

  assert.equal(spans.length, 1);
  assert.equal(
    text.slice(spans[0].start, spans[0].end),
    '/*partial v foo*/body/*partial ^ bar*/more/*partial ^ foo*/',
  );
});

test('findNamedPairedBlockInteriors survives mismatched end markers', () => {
  const text = '/*partial v foo*/body/*partial ^ bar*/more/*partial ^ foo*/';
  const interiors = findNamedPairedBlockInteriors(text, PARTIAL_MARKER_SETS.slice(0, 1));

  assert.equal(interiors.length, 1);
  assert.equal(text.slice(interiors[0].start, interiors[0].end), 'body/*partial ^ bar*/more');
});

test('findPairedBlockSpans pairs replace boundaries', () => {
  const text = [
    '/*replace-start*/',
    'old',
    '/*with*/',
    'new',
    '/*replace-end*/',
  ].join('\n');
  const spans = findPairedBlockSpans(text, REPLACE_MARKER_SETS.slice(0, 1));

  assert.equal(spans.length, 1);
  assert.ok(text.slice(spans[0].start, spans[0].end).includes('replace-start'));
  assert.ok(text.slice(spans[0].start, spans[0].end).includes('replace-end'));
});
