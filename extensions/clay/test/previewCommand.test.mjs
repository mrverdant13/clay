import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import { installVscodeMock } from './vscode-mock.mjs';

const { registeredCommands } = installVscodeMock();

const require = createRequire(import.meta.url);
const {
  PREVIEW_GENERATED_COMMAND_ID,
  PREVIEW_TEMPLATE_COMMAND_ID,
  registerPreviewCommands,
} = require('./out/previewCommand.cjs');

registerPreviewCommands({ subscriptions: [] });

test('preview command ids match package.json contributions', () => {
  assert.equal(PREVIEW_TEMPLATE_COMMAND_ID, 'clay.previewTemplate');
  assert.equal(PREVIEW_GENERATED_COMMAND_ID, 'clay.previewGenerated');
});

test('registerPreviewCommands wires template and generated handlers', () => {
  const commandIds = registeredCommands.map((entry) => entry.id);
  assert.deepEqual(commandIds, [
    PREVIEW_TEMPLATE_COMMAND_ID,
    PREVIEW_GENERATED_COMMAND_ID,
  ]);
  assert.equal(typeof registeredCommands[0].handler, 'function');
  assert.equal(typeof registeredCommands[1].handler, 'function');
});
