import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
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

export default defineConfig({
  label: 'integration',
  files: 'e2e/**/*.test.cjs',
  version: '1.85.2',
  workspaceFolder: join(
    extensionRoot,
    'e2e',
    'fixtures',
    'sample-brick',
    'sample-brick.code-workspace',
  ),
  extensionDevelopmentPath: extensionRoot,
  launchArgs: [
    '--disable-extensions',
    '--disable-gpu',
    '--disable-workspace-trust',
    '--user-data-dir=/tmp/clay-vsc-test',
  ],
  env: {
    ...process.env,
    PATH: resolvePathEnv(),
  },
  mocha: {
    ui: 'tdd',
    timeout: 120_000,
  },
});
