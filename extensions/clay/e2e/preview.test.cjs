const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { existsSync } = require('node:fs');
const { join } = require('node:path');

const vscode = require('vscode');

const { fixtureMainDart, fixtureRoot } = require('./helpers/paths.cjs');

function monorepoRoot() {
  const folders = vscode.workspace.workspaceFolders ?? [];
  const match = folders.find((folder) =>
    existsSync(join(folder.uri.fsPath, 'packages', 'clay_cli', 'bin', 'clay.dart')),
  );
  assert.ok(match, 'expected monorepo workspace folder');
  return match.uri.fsPath;
}

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
  assert.doesNotMatch(previewDocument.getText(), /remove-start/);
}

suite('Preview command', () => {
  suiteSetup(async () => {
    const wrapperPath = join(fixtureRoot, 'tools', 'clay.sh');
    await vscode.workspace
      .getConfiguration('clay')
      .update('cliPath', wrapperPath, vscode.ConfigurationTarget.Workspace);
  });

  test('extension helpers resolve scope, CLI, and template preview for the fixture', async () => {
    const { findBrickScopeForFile } = require('../test/out/brickScope.cjs');
    const { resolveClayCli } = require('../test/out/clayCli.cjs');
    const { runTemplatePreview } = require('../test/out/previewRunner.cjs');

    const scope = findBrickScopeForFile(fixtureMainDart);
    assert.ok(scope, 'expected brick scope for fixture main.dart');

    const cli = await resolveClayCli();
    const output = await runTemplatePreview({
      scope,
      filePath: fixtureMainDart,
      cli,
    });

    assert.match(output, /void main\(\)/);
    assert.doesNotMatch(output, /remove-start/);
  });

  test('dart run clay preview succeeds for the fixture file', () => {
    const root = monorepoRoot();
    const clayScript = join(root, 'packages', 'clay_cli', 'bin', 'clay.dart');
    const stdout = execFileSync(
      'dart',
      [
        'run',
        clayScript,
        'preview',
        '--file',
        fixtureMainDart,
        '--config',
        join(fixtureRoot, 'clay.yaml'),
        '--cwd',
        fixtureRoot,
        '--template-only',
      ],
      { cwd: fixtureRoot, encoding: 'utf8' },
    );

    assert.match(stdout, /void main\(\)/);
    assert.doesNotMatch(stdout, /remove-start/);
  });

  test('clay.previewTemplate opens a preview document for the fixture file', async function () {
    this.timeout(90_000);

    const uri = vscode.Uri.file(fixtureMainDart);
    const document = await vscode.workspace.openTextDocument(uri);
    await vscode.window.showTextDocument(document, { preview: false });

    await expectPreviewDocument(async () => {
      await vscode.commands.executeCommand('clay.previewTemplate', uri);
    });
  });

  test('clay.previewGenerated completes without prompting when no variables are required', async function () {
    this.timeout(90_000);

    const uri = vscode.Uri.file(fixtureMainDart);
    const document = await vscode.workspace.openTextDocument(uri);
    await vscode.window.showTextDocument(document, { preview: false });

    await expectPreviewDocument(async () => {
      await vscode.commands.executeCommand('clay.previewGenerated', uri);
    });
  });
});
