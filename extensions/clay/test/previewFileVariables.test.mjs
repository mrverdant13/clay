import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const { resolvePreviewVariables } = require('./out/previewFileVariables.cjs');
const { parseClayConfig } = require('./out/clayConfig.cjs');

test('resolvePreviewVariables returns an empty list when no Mustache tags remain', () => {
  const config = parseClayConfig('');
  const variables = resolvePreviewVariables([], 'void main() {}', config);
  assert.deepEqual(variables, []);
});

test('resolvePreviewVariables prefers brick.yaml definitions and infers unknown names', () => {
  const config = parseClayConfig(`
replacements:
  - from: Widget
    to: "{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}{{^use_riverpod}}StatelessWidget{{/use_riverpod}}"
`);

  const brickVariables = [
    {
      name: 'use_riverpod',
      type: 'boolean',
      default: false,
    },
    {
      name: 'unused',
      type: 'string',
    },
  ];

  const variables = resolvePreviewVariables(
    brickVariables,
    'class App extends Widget {}',
    config,
  );

  assert.deepEqual(variables, [
    {
      name: 'use_riverpod',
      type: 'boolean',
      default: false,
    },
  ]);
});

test('resolvePreviewVariables infers string variables from value tags', () => {
  const config = parseClayConfig('');
  const variables = resolvePreviewVariables(
    [],
    'const title = /*{{app_name}}*/;',
    config,
  );

  assert.deepEqual(variables, [{ name: 'app_name', type: 'string' }]);
});

test('resolvePreviewVariables infers boolean variables from section tags', () => {
  const config = parseClayConfig('');
  const variables = resolvePreviewVariables(
    [],
    '/*{{#feature}}*/enabled/*{{/feature}}*/',
    config,
  );

  assert.deepEqual(variables, [{ name: 'feature', type: 'boolean' }]);
});
