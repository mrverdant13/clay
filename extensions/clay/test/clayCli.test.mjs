import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const { CLAY_CLI_SCRIPT_RELATIVE_PATH, resolveWorkspaceClayScript } = require(
  './out/workspaceClayScript.cjs',
);

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = join(extensionRoot, '..', '..');

test('resolveWorkspaceClayScript finds clay.dart in the Clay repository', () => {
  const scriptPath = resolveWorkspaceClayScript([repoRoot]);

  assert.ok(scriptPath);
  assert.equal(
    scriptPath,
    join(repoRoot, CLAY_CLI_SCRIPT_RELATIVE_PATH),
  );
});

test('resolveWorkspaceClayScript returns undefined when script is missing', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-cli-resolve-'));
  try {
    assert.equal(resolveWorkspaceClayScript([tempDir]), undefined);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test('resolveWorkspaceClayScript checks folders in order', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-cli-resolve-'));
  try {
    const nestedRoot = join(tempDir, 'workspace');
    const scriptDir = join(nestedRoot, dirname(CLAY_CLI_SCRIPT_RELATIVE_PATH));
    mkdirSync(scriptDir, { recursive: true });
    writeFileSync(join(nestedRoot, CLAY_CLI_SCRIPT_RELATIVE_PATH), '');

    assert.equal(
      resolveWorkspaceClayScript([join(tempDir, 'missing'), nestedRoot]),
      join(nestedRoot, CLAY_CLI_SCRIPT_RELATIVE_PATH),
    );
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});
