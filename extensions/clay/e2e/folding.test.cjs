const assert = require('node:assert/strict');
const { existsSync } = require('node:fs');
const { join } = require('node:path');

const vscode = require('vscode');

const { findPairedBlockSpans } = require('../test/out/annotationBlockPairing.cjs');
const {
  REMOVE_MARKER_SETS,
  REPLACE_MARKER_SETS,
} = require('../test/out/annotationMarkerSets.cjs');
const { fixtureMainDart } = require('./helpers/paths.cjs');

suite('Block folding', () => {
  test('reference fixture exposes paired annotation blocks in a real editor', async () => {
    const uri = vscode.Uri.file(fixtureMainDart);
    const document = await vscode.workspace.openTextDocument(uri);
    await vscode.window.showTextDocument(document);

    const spans = [
      ...findPairedBlockSpans(document.getText(), REMOVE_MARKER_SETS),
      ...findPairedBlockSpans(document.getText(), REPLACE_MARKER_SETS),
    ];

    assert.ok(
      spans.length >= 2,
      `expected paired annotation blocks in fixture, got ${spans.length}`,
    );
  });
});

suite('Workspace clay CLI', () => {
  test('multi-root workspace includes the monorepo clay.dart entrypoint', () => {
    const folders = vscode.workspace.workspaceFolders ?? [];
    assert.ok(folders.length >= 2, 'expected sample-brick and monorepo workspace folders');

    const hasClayScript = folders.some((folder) =>
      existsSync(join(folder.uri.fsPath, 'packages', 'clay_cli', 'bin', 'clay.dart')),
    );

    assert.ok(hasClayScript, 'expected workspace folder containing packages/clay_cli/bin/clay.dart');
  });
});
