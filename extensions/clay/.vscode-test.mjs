import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { defineConfig } from '@vscode/test-cli';
import { fileURLToPath } from 'node:url';

const extensionRoot = dirname(fileURLToPath(import.meta.url));

function resolvePathEnv() {
  const entries = (process.env.PATH ?? '').split(':').filter(Boolean);
  const filtered = entries.filter((entry) => {
    if (process.platform === 'win32') {
      return !existsSync(join(entry, 'clay.exe')) && !existsSync(join(entry, 'clay.bat'));
    }
    return !existsSync(join(entry, 'clay'));
  });

  try {
    const dartPath = execSync('which dart', { encoding: 'utf8' }).trim();
    if (dartPath.length > 0) {
      filtered.unshift(dirname(dartPath));
    }
  } catch {
    // Dart may already be on PATH (for example in CI after setup-dart).
  }

  return [...new Set(filtered)].join(':');
}

const workspaceFolder = join(
  extensionRoot,
  'e2e',
  'fixtures',
  'sample-brick',
  'sample-brick.code-workspace',
);

const shared = {
  version: '1.85.2',
  workspaceFolder,
  extensionDevelopmentPath: extensionRoot,
  env: {
    ...process.env,
    PATH: resolvePathEnv(),
  },
  mocha: {
    ui: 'tdd',
    timeout: 120_000,
  },
};

const baseLaunchArgs = ['--disable-extensions', '--disable-gpu'];

export default defineConfig([
  {
    label: 'integration',
    files: 'e2e/*.test.cjs',
    ...shared,
    launchArgs: [
      ...baseLaunchArgs,
      '--disable-workspace-trust',
      '--user-data-dir=/tmp/clay-vsc-test',
    ],
  },
  {
    label: 'trustedWorkspaceTests',
    files: 'e2e/trust/trusted.test.cjs',
    ...shared,
    launchArgs: [
      ...baseLaunchArgs,
      '--disable-workspace-trust',
      '--user-data-dir',
      join(tmpdir(), 'clay-vsc-trusted-test'),
    ],
  },
  {
    label: 'untrustedWorkspaceTests',
    files: 'e2e/trust/untrusted.test.cjs',
    ...shared,
    env: {
      ...shared.env,
      CLAY_E2E_SIMULATE_UNTRUSTED: '1',
    },
    mocha: {
      ...shared.mocha,
      require: join(extensionRoot, 'e2e', 'helpers', 'trust-preload.cjs'),
    },
    launchArgs: [
      ...baseLaunchArgs,
      '--user-data-dir',
      join(tmpdir(), 'clay-vsc-untrusted-test'),
    ],
  },
]);
