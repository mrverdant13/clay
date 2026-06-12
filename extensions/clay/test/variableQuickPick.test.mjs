import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import { installVscodeMock } from './vscode-mock.mjs';

const { mockVscode } = installVscodeMock();

const require = createRequire(import.meta.url);
const { collectPreviewVariableValues } = require('./out/variableQuickPick.cjs');

test('collectPreviewVariableValues prompts for each variable in order', async () => {
  const prompts = [];
  mockVscode.window.showInputBox = async (options) => {
    prompts.push(options);
    return options.placeHolder === 'name' ? 'Ada' : 'ignored';
  };
  mockVscode.window.showQuickPick = async (options, settings) => {
    prompts.push({ options, settings });
    return options.find((entry) => entry.picked) ?? options[0];
  };

  const values = await collectPreviewVariableValues([
    { name: 'name', type: 'string', description: 'Display name' },
    { name: 'enabled', type: 'boolean', default: true },
    { name: 'mode', type: 'enum', values: ['a', 'b'], default: 'b' },
  ]);

  assert.deepEqual(values, { name: 'Ada', enabled: true, mode: 'b' });
  assert.equal(prompts.length, 3);
});

test('collectPreviewVariableValues returns undefined when a prompt is cancelled', async () => {
  mockVscode.window.showInputBox = async () => undefined;

  const values = await collectPreviewVariableValues([
    { name: 'name', type: 'string' },
  ]);

  assert.equal(values, undefined);
});

test('collectPreviewVariableValues applies saved defaults to enum prompts', async () => {
  mockVscode.window.showQuickPick = async (options) =>
    options.find((entry) => entry.label === 'riverpod') ?? options[0];

  const values = await collectPreviewVariableValues(
    [{ name: 'state_mgmt', type: 'enum', values: ['bloc', 'riverpod'] }],
    { state_mgmt: 'riverpod' },
  );

  assert.deepEqual(values, { state_mgmt: 'riverpod' });
});
