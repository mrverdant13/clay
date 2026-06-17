import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

import { installVscodeMock } from './vscode-mock.mjs';

installVscodeMock();

const require = createRequire(import.meta.url);

const { CLAY_CLI_SCRIPT_RELATIVE_PATH, resolveWorkspaceClayScript } = require(
  './out/workspaceClayScript.cjs',
);
const {
  getClayCliVersion,
  runClayCompat,
  setClayCliExecFileForTests,
  setClayCompatExecFileForTests,
} = require('./out/clayCli.cjs');

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

test('getClayCliVersion reads --version stdout from the CLI subprocess', async () => {
  setClayCliExecFileForTests(async (_executable, args) => {
    assert.deepEqual(args, ['--version']);
    return { stdout: '0.0.1-dev.42\n', stderr: '' };
  });

  try {
    const version = await getClayCliVersion({ executable: '/bin/clay', prefixArgs: [] });
    assert.equal(version, '0.0.1-dev.42');
  } finally {
    setClayCliExecFileForTests();
  }
});

test('runClayCompat invokes compat with --config and --cwd from brick scope', async () => {
  /** @type {{ executable?: string; args?: string[]; options?: { cwd: string; timeout: number } } | null} */
  let captured = null;

  setClayCompatExecFileForTests(async (executable, args, options) => {
    captured = { executable, args, options };
    return { stdout: '', stderr: '' };
  });

  try {
    const result = await runClayCompat(
      { executable: '/bin/clay', prefixArgs: ['run', 'clay.dart'] },
      { configPath: '/proj/clay.yaml', projectRoot: '/proj' },
    );

    assert.deepEqual(result, { exitCode: 0, stderr: '' });
    assert.deepEqual(captured, {
      executable: '/bin/clay',
      args: [
        'run',
        'clay.dart',
        'compat',
        '--config',
        '/proj/clay.yaml',
        '--cwd',
        '/proj',
      ],
      options: { cwd: '/proj', timeout: 10_000 },
    });
  } finally {
    setClayCompatExecFileForTests();
  }
});

test('runClayCompat maps non-zero exit code and stderr from subprocess failure', async () => {
  setClayCompatExecFileForTests(async () => {
    const error = new Error('clay compat failed');
    error.code = 70;
    error.stderr =
      'The current clay version is 0.0.1-dev.1.\n' +
      'This project requires clay version ^0.2.0.';
    throw error;
  });

  try {
    const result = await runClayCompat(
      { executable: 'clay', prefixArgs: [] },
      { configPath: '/brick/clay.yaml', projectRoot: '/brick' },
    );

    assert.equal(result.exitCode, 70);
    assert.equal(
      result.stderr,
      'The current clay version is 0.0.1-dev.1.\n' +
        'This project requires clay version ^0.2.0.',
    );
  } finally {
    setClayCompatExecFileForTests();
  }
});
