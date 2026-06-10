import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const {
  loadSavedPreviewVariables,
  resolvePreviewDefault,
  savePreviewVariables,
} = require('./out/previewVariableState.cjs');

function createMockContext(initial = {}) {
  const state = new Map(Object.entries(initial));

  return {
    globalState: {
      get(key) {
        return state.get(key);
      },
      async update(key, value) {
        state.set(key, value);
      },
    },
    _state: state,
  };
}

test('resolvePreviewDefault prefers saved values over brick defaults', () => {
  const variable = {
    name: 'title',
    type: 'string',
    default: 'Default',
  };

  assert.equal(resolvePreviewDefault(variable, { title: 'Saved' }), 'Saved');
  assert.equal(resolvePreviewDefault(variable, {}), 'Default');
});

test('loadSavedPreviewVariables keeps only values matching variable types', () => {
  const context = createMockContext({
    'clay.previewVariables./tmp/demo/brick-gen.json': {
      use_riverpod: true,
      platform: 'invalid',
      title: 'My App',
    },
  });

  const variables = [
    { name: 'use_riverpod', type: 'boolean' },
    { name: 'platform', type: 'enum', values: ['ios', 'android'] },
    { name: 'title', type: 'string' },
  ];

  assert.deepEqual(
    loadSavedPreviewVariables(context, '/tmp/demo/brick-gen.json', variables),
    {
    use_riverpod: true,
      title: 'My App',
    },
  );
});

test('savePreviewVariables merges values into extension global state', async () => {
  const context = createMockContext({
    'clay.previewVariables./tmp/demo/brick-gen.json': { title: 'Old' },
  });

  await savePreviewVariables(context, '/tmp/demo/brick-gen.json', { use_riverpod: true });

  assert.deepEqual(context._state.get('clay.previewVariables./tmp/demo/brick-gen.json'), {
    title: 'Old',
    use_riverpod: true,
  });
});
