import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import { installVscodeMock } from './vscode-mock.mjs';

const { mockVscode, configuration } = installVscodeMock();
const builtInGetConfiguration = mockVscode.workspace.getConfiguration;

const require = createRequire(import.meta.url);
const { readAnnotationConfig } = require('./out/annotationConfigReader.cjs');
const { removedContentBackground } = require('./out/annotationColors.cjs');

test('readAnnotationConfig delegates to workspace clay.colors settings', () => {
  mockVscode.workspace.getConfiguration = () => ({
    get: (key, defaultValue) =>
      key === 'colors.remove.markerForeground' ? '#abcdef' : defaultValue,
  });

  const config = readAnnotationConfig();
  assert.equal(config.remove.markerForeground, '#abcdef');
  assert.equal(config.remove.contentBackground, removedContentBackground);
});

test('readAnnotationConfig returns defaults when settings are unset', () => {
  mockVscode.workspace.getConfiguration = () => ({
    get: (_key, defaultValue) => defaultValue,
  });

  const config = readAnnotationConfig();
  assert.equal(config.spacing.markerForeground, '#A0A1A7');
  assert.equal(config.mustache.tagForeground, '#C678DD');
});

test('readAnnotationConfig uses built-in mock defaults when settings are unset', () => {
  configuration.clear();
  mockVscode.workspace.getConfiguration = builtInGetConfiguration;

  const config = readAnnotationConfig();

  assert.equal(config.remove.markerForeground, '#F48771');
  assert.equal(config.spacing.markerForeground, '#A0A1A7');
  assert.equal(config.mustache.tagForeground, '#C678DD');
});
