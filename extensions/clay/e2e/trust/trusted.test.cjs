const assert = require('node:assert/strict');
const { join } = require('node:path');

const vscode = require('vscode');

const { fixtureMainDart, fixtureRoot } = require('../helpers/paths.cjs');

const EXTENSION_ID = 'mrverdant13.clay';

/**
 * Waits for the preview command to open an untitled preview document.
 *
 * @param {() => Promise<void>} runPreview
 */
async function expectPreviewDocument(runPreview) {
  /** @type {Promise<vscode.TextDocument>} */
  const opened = new Promise((resolve, reject) => {
    const timeout = setTimeout(() => {
      disposable.dispose();
      reject(new Error('Timed out waiting for preview document to open'));
    }, 60_000);

    const disposable = vscode.workspace.onDidOpenTextDocument((document) => {
      if (!document.isUntitled) {
        return;
      }
      clearTimeout(timeout);
      disposable.dispose();
      resolve(document);
    });
  });

  await runPreview();
  const previewDocument = await opened;
  assert.match(previewDocument.getText(), /void main\(\)/);
}

suite('Trusted workspace', () => {
  suiteSetup(async () => {
    const wrapperPath = join(fixtureRoot, 'tools', 'clay.sh');
    await vscode.workspace
      .getConfiguration('clay')
      .update('cliPath', wrapperPath, vscode.ConfigurationTarget.Workspace);
  });

  test('workspace is trusted', () => {
    assert.equal(vscode.workspace.isTrusted, true);
  });

  test('Clay extension activates in a trusted workspace', async () => {
    const extension = vscode.extensions.getExtension(EXTENSION_ID);
    assert.ok(extension, `expected extension ${EXTENSION_ID} to be installed`);

    if (!extension.isActive) {
      await extension.activate();
    }

    assert.ok(extension.isActive, 'Clay extension should activate in a trusted workspace');
  });

  test('clay.previewTemplate opens a preview document in a trusted workspace', async function () {
    this.timeout(90_000);

    const uri = vscode.Uri.file(fixtureMainDart);
    const document = await vscode.workspace.openTextDocument(uri);
    await vscode.window.showTextDocument(document, { preview: false });

    await expectPreviewDocument(async () => {
      await vscode.commands.executeCommand('clay.previewTemplate', uri);
    });
  });
});
