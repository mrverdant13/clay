const assert = require('node:assert/strict');
const { execFileSync } = require('node:child_process');
const { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } = require('node:fs');
const { tmpdir } = require('node:os');
const { join } = require('node:path');

const vscode = require('vscode');

function monorepoRoot() {
  const folders = vscode.workspace.workspaceFolders ?? [];
  const match = folders.find((folder) =>
    existsSync(join(folder.uri.fsPath, 'packages', 'clay_cli', 'bin', 'clay.dart')),
  );
  assert.ok(match, 'expected monorepo workspace folder');
  return match.uri.fsPath;
}

function workspaceClayScript(root) {
  return join(root, 'packages', 'clay_cli', 'bin', 'clay.dart');
}

suite('Clay CLI subprocess', () => {
  test('dart run --version reports the workspace CLI version', () => {
    const root = monorepoRoot();
    const stdout = execFileSync(
      'dart',
      ['run', workspaceClayScript(root), '--version'],
      { encoding: 'utf8' },
    );

    assert.match(stdout.trim(), /^0\.0\.1-dev\.\d+$/);
  });

  test('dart run compat succeeds for a compatible clay.yaml', () => {
    const root = monorepoRoot();
    const tempDir = mkdtempSync(join(tmpdir(), 'clay-compat-e2e-'));
    try {
      writeFileSync(
        join(tempDir, 'clay.yaml'),
        'reference: reference\ntarget: brick/__brick__\n',
      );
      mkdirSync(join(tempDir, 'reference'), { recursive: true });

      execFileSync(
        'dart',
        [
          'run',
          workspaceClayScript(root),
          'compat',
          '--config',
          join(tempDir, 'clay.yaml'),
          '--cwd',
          tempDir,
        ],
        { encoding: 'utf8' },
      );
    } finally {
      rmSync(tempDir, { recursive: true, force: true });
    }
  });
});
