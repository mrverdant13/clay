const assert = require('node:assert/strict');

const vscode = require('vscode');

const EXTENSION_ID = 'mrverdant13.clay';

suite('Extension activation', () => {
  test('Clay extension is active on startup', async () => {
    const extension = vscode.extensions.getExtension(EXTENSION_ID);
    assert.ok(extension, `expected extension ${EXTENSION_ID} to be installed`);

    if (!extension.isActive) {
      await extension.activate();
    }

    assert.ok(extension.isActive, 'Clay extension should activate on startup');
  });
});
