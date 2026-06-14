const assert = require('node:assert/strict');

const vscode = require('vscode');

const { fixtureMainDart } = require('../helpers/paths.cjs');

const EXTENSION_ID = 'mrverdant13.clay';

/**
 * Waits briefly to confirm no untitled preview document opens.
 *
 * @param {() => Promise<void>} runPreview
 */
async function expectNoPreviewDocument(runPreview) {
  let previewOpened = false;
  const disposable = vscode.workspace.onDidOpenTextDocument((document) => {
    if (document.isUntitled) {
      previewOpened = true;
    }
  });

  try {
    await runPreview();
    await new Promise((resolve) => setTimeout(resolve, 3_000));
    assert.equal(
      previewOpened,
      false,
      'preview should not open in an untrusted workspace',
    );
  } finally {
    disposable.dispose();
  }
}

suite('Untrusted workspace', () => {
  test('workspace is not trusted', () => {
    assert.equal(vscode.workspace.isTrusted, false);
  });

  test('Clay extension activates with limited support in Restricted Mode', async () => {
    const extension = vscode.extensions.getExtension(EXTENSION_ID);
    assert.ok(extension, `expected extension ${EXTENSION_ID} to be installed`);

    if (!extension.isActive) {
      await extension.activate();
    }

    assert.ok(
      extension.isActive,
      'Clay extension should activate with limited support in Restricted Mode',
    );
  });

  test('clay.previewTemplate does not open a preview document in Restricted Mode', async function () {
    this.timeout(30_000);

    const uri = vscode.Uri.file(fixtureMainDart);
    const document = await vscode.workspace.openTextDocument(uri);
    await vscode.window.showTextDocument(document, { preview: false });

    await expectNoPreviewDocument(async () => {
      await vscode.commands.executeCommand('clay.previewTemplate', uri);
    });
  });
});
