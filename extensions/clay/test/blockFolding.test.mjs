import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import { createMockDocument, installVscodeMock } from './vscode-mock.mjs';

function loadBlockFoldingProvider() {
  const { foldingProviders } = installVscodeMock();
  const require = createRequire(import.meta.url);
  const modulePath = require.resolve('./out/blockFolding.cjs');
  delete require.cache[modulePath];
  const { registerBlockFolding } = require(modulePath);
  registerBlockFolding({ subscriptions: [] });
  const provider = foldingProviders[0];
  assert.ok(provider, 'folding provider was not registered');
  return provider;
}

test('provideFoldingRanges folds remove blocks in supported files', () => {
  const provider = loadBlockFoldingProvider();
  const text = [
    'void main() {',
    '  /*remove-start*/',
    '  scaffold();',
    '  /*remove-end*/',
    '}',
  ].join('\n');
  const document = createMockDocument(text);

  const ranges = provider.provideFoldingRanges(document);
  assert.equal(ranges.length, 1);
  assert.equal(ranges[0].start, 1);
  assert.equal(ranges[0].end, 3);
});

test('provideFoldingRanges returns no ranges for unsupported files', () => {
  const provider = loadBlockFoldingProvider();
  const document = createMockDocument(
    '/*remove-start*/x/*remove-end*/',
    '/project/README.txt',
  );

  assert.deepEqual(provider.provideFoldingRanges(document), []);
});
