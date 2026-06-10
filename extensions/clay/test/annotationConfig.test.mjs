import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const { resolveAnnotationConfig } = require('./out/annotationConfig.cjs');
const {
  insertedContentBackground,
  insertedMarkerForeground,
  mustacheCommentBackground,
  mustacheDropFlagForeground,
  mustacheTagForeground,
  partialMarkerForeground,
  partialPayloadBackground,
  removedContentBackground,
  removedMarkerForeground,
  replaceBoundaryMarkerForeground,
  replaceOriginalBackground,
  replaceReplacementBackground,
  replaceWithMarkerForeground,
  spacingMarkerBackground,
  spacingMarkerForeground,
} = require('./out/annotationColors.cjs');

test('resolveAnnotationConfig returns built-in defaults when no overrides are set', () => {
  const config = resolveAnnotationConfig((_key, defaultValue) => defaultValue);

  assert.equal(config.remove.markerForeground, removedMarkerForeground);
  assert.equal(config.remove.contentBackground, removedContentBackground);
  assert.equal(config.replace.boundaryMarkerForeground, replaceBoundaryMarkerForeground);
  assert.equal(config.replace.withMarkerForeground, replaceWithMarkerForeground);
  assert.equal(config.replace.originalBackground, replaceOriginalBackground);
  assert.equal(config.replace.replacementBackground, replaceReplacementBackground);
  assert.equal(config.insert.markerForeground, insertedMarkerForeground);
  assert.equal(config.insert.contentBackground, insertedContentBackground);
  assert.equal(config.partial.markerForeground, partialMarkerForeground);
  assert.equal(config.partial.payloadBackground, partialPayloadBackground);
  assert.equal(config.mustache.tagForeground, mustacheTagForeground);
  assert.equal(config.mustache.commentBackground, mustacheCommentBackground);
  assert.equal(config.mustache.dropFlagForeground, mustacheDropFlagForeground);
  assert.equal(config.spacing.markerForeground, spacingMarkerForeground);
  assert.equal(config.spacing.markerBackground, spacingMarkerBackground);
});

test('resolveAnnotationConfig applies user overrides for clay.colors settings', () => {
  const overrides = {
    'colors.remove.markerForeground': '#111111',
    'colors.replace.replacementBackground': 'rgba(0, 0, 0, 0.5)',
    'colors.spacing.markerBackground': 'rgba(255, 255, 255, 0.2)',
  };

  const config = resolveAnnotationConfig((key, defaultValue) => overrides[key] ?? defaultValue);

  assert.equal(config.remove.markerForeground, '#111111');
  assert.equal(config.remove.contentBackground, removedContentBackground);
  assert.equal(config.replace.replacementBackground, 'rgba(0, 0, 0, 0.5)');
  assert.equal(config.spacing.markerBackground, 'rgba(255, 255, 255, 0.2)');
});
