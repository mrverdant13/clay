import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import { createMockDocument, installVscodeMock } from './vscode-mock.mjs';

installVscodeMock();

const require = createRequire(import.meta.url);
const {
  captureToRange,
  interiorsToRanges,
  matchToRange,
  patternToRanges,
  spanToFoldingRange,
} = require('./out/rangeUtils.cjs');

/** @param {import('./vscode-mock.mjs').createMockDocument extends (...args: any) => infer R ? R : never} document @param {{ start: { line: number; character: number }; end: { line: number; character: number } }} range */
function rangeText(document, range) {
  return document.getText(range);
}

test('interiorsToRanges maps byte offsets to document ranges', () => {
  const document = createMockDocument('alpha beta gamma');
  const ranges = interiorsToRanges(document, [{ start: 0, end: 5 }, { start: 6, end: 10 }]);

  assert.equal(ranges.length, 2);
  assert.equal(ranges[0].start.line, 0);
  assert.equal(ranges[0].start.character, 0);
  assert.equal(ranges[0].end.character, 5);
  assert.equal(ranges[1].start.character, 6);
  assert.equal(ranges[1].end.character, 10);
});

test('patternToRanges finds every regex match in document order', () => {
  const text = '/*remove-start*/ x /*remove-end*/';
  const document = createMockDocument(text);
  const ranges = patternToRanges(document, text, /\/\*remove-(?:start|end)\*\//g);

  assert.equal(ranges.length, 2);
  assert.equal(rangeText(document, ranges[0]), '/*remove-start*/');
  assert.equal(rangeText(document, ranges[1]), '/*remove-end*/');
});

test('matchToRange spans the full regex match', () => {
  const text = 'prefix #drop# suffix';
  const document = createMockDocument(text);
  const match = /#drop#/.exec(text);
  assert.ok(match);

  const range = matchToRange(document, match);
  assert.equal(range.start.character, 7);
  assert.equal(range.end.character, 13);
  assert.equal(rangeText(document, range), '#drop#');
});

test('captureToRange resolves first and last capture occurrences', () => {
  const text = '/*partial v foo*/';
  const document = createMockDocument(text);
  const match = /\/\*partial v ([^*]+)\*\//.exec(text);
  assert.ok(match);

  const first = captureToRange(document, match, 1, 'first');
  const last = captureToRange(document, match, 1, 'last');
  assert.ok(first);
  assert.ok(last);
  assert.equal(rangeText(document, first), 'foo');
  assert.equal(rangeText(document, last), 'foo');
});

test('captureToRange returns undefined for empty captures', () => {
  const text = 'no capture';
  const document = createMockDocument(text);
  const match = /(missing)?/.exec(text);
  assert.ok(match);

  assert.equal(captureToRange(document, match, 1), undefined);
});

test('spanToFoldingRange folds multi-line block interiors', () => {
  const text = [
    'void main() {',
    '  /*remove-start*/',
    '  scaffold();',
    '  /*remove-end*/',
    '}',
  ].join('\n');
  const document = createMockDocument(text);
  const start = text.indexOf('/*remove-start*/');
  const end = text.indexOf('/*remove-end*/') + '/*remove-end*/'.length;

  const foldingRange = spanToFoldingRange(document, { start, end });
  assert.ok(foldingRange);
  assert.equal(foldingRange.start, 1);
  assert.equal(foldingRange.end, 2);
});

test('spanToFoldingRange keeps same-line leading code visible', () => {
  const text = 'code /*remove-start*/ inner /*remove-end*/ tail';
  const document = createMockDocument(text);
  const start = text.indexOf('/*remove-start*/');
  const end = text.indexOf('/*remove-end*/') + '/*remove-end*/'.length;

  assert.equal(spanToFoldingRange(document, { start, end }), undefined);
});

test('spanToFoldingRange keeps trailing code after end marker visible', () => {
  const text = [
    '/*remove-start*/',
    'line one',
    'line two /*remove-end*/ trailing',
  ].join('\n');
  const document = createMockDocument(text);
  const start = text.indexOf('/*remove-start*/');
  const endMarkerStart = text.indexOf('/*remove-end*/');
  const end = endMarkerStart + '/*remove-end*/'.length;

  const foldingRange = spanToFoldingRange(document, {
    start,
    end,
    endMarkerStart,
  });
  assert.ok(foldingRange);
  assert.equal(foldingRange.start, 0);
  assert.equal(foldingRange.end, 1);
});
