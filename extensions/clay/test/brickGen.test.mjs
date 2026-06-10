import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);

const {
  DEFAULT_REFERENCE_PATH,
  DEFAULT_TARGET_PATH,
  parseBrickGenConfig,
  loadBrickGenConfig,
  resolvePathFromProjectRoot,
  resolveReferencePath,
  resolveTargetPath,
} = require('./out/brickGen.cjs');

test('parseBrickGenConfig applies defaults for omitted path fields', () => {
  const config = parseBrickGenConfig('{}');

  assert.equal(config.reference, DEFAULT_REFERENCE_PATH);
  assert.equal(config.target, DEFAULT_TARGET_PATH);
  assert.deepEqual(config.ignore, []);
});

test('parseBrickGenConfig reads explicit path fields', () => {
  const config = parseBrickGenConfig(
    JSON.stringify({
      reference: 'src/ref',
      target: 'out/template',
      ignore: ['*.png'],
    }),
  );

  assert.equal(config.reference, 'src/ref');
  assert.equal(config.target, 'out/template');
  assert.deepEqual(config.ignore, ['*.png']);
});

test('loadBrickGenConfig reads from disk', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-brick-gen-'));
  try {
    const configPath = join(tempDir, 'brick-gen.json');
    writeFileSync(
      configPath,
      JSON.stringify({ reference: 'refs/main', target: 'dist/brick' }),
    );

    const config = loadBrickGenConfig(configPath);
    assert.equal(config.reference, 'refs/main');
    assert.equal(config.target, 'dist/brick');
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test('resolvePathFromProjectRoot joins relative paths', () => {
  const resolved = resolvePathFromProjectRoot('/project', 'reference');
  assert.equal(resolved, join('/project', 'reference'));
});

test('resolvePathFromProjectRoot normalizes absolute paths', () => {
  const resolved = resolvePathFromProjectRoot('/project', '/abs/reference');
  assert.equal(resolved, '/abs/reference');
});

test('resolveReferencePath and resolveTargetPath use config fields', () => {
  const config = parseBrickGenConfig(
    JSON.stringify({ reference: 'refs/main', target: 'dist/brick' }),
  );

  assert.equal(resolveReferencePath('/project', config), join('/project', 'refs/main'));
  assert.equal(resolveTargetPath('/project', config), join('/project', 'dist/brick'));
});
