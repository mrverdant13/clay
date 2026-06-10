import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';

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

test('parseBrickGenConfig falls back to defaults for unexpected field types', () => {
  const config = parseBrickGenConfig(
    JSON.stringify({
      reference: 42,
      target: ['out/template'],
      ignore: '*.png',
    }),
  );

  assert.equal(config.reference, DEFAULT_REFERENCE_PATH);
  assert.equal(config.target, DEFAULT_TARGET_PATH);
  assert.deepEqual(config.ignore, []);
});

test('parseBrickGenConfig keeps only string entries in ignore arrays', () => {
  const config = parseBrickGenConfig(
    JSON.stringify({
      ignore: ['*.png', 7, null, '*.jpg'],
    }),
  );

  assert.deepEqual(config.ignore, ['*.png', '*.jpg']);
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
  const projectRoot = join(tmpdir(), 'project');
  const resolved = resolvePathFromProjectRoot(projectRoot, 'reference');
  assert.equal(resolved, join(projectRoot, 'reference'));
});

test('resolvePathFromProjectRoot normalizes absolute paths', () => {
  const absoluteReference = join(tmpdir(), 'abs-reference');
  const resolved = resolvePathFromProjectRoot(join(tmpdir(), 'project'), absoluteReference);
  assert.equal(resolved, absoluteReference);
});

test('resolveReferencePath and resolveTargetPath use config fields', () => {
  const projectRoot = join(tmpdir(), 'project');
  const config = parseBrickGenConfig(
    JSON.stringify({ reference: 'refs/main', target: 'dist/brick' }),
  );

  assert.equal(resolveReferencePath(projectRoot, config), join(projectRoot, 'refs/main'));
  assert.equal(resolveTargetPath(projectRoot, config), join(projectRoot, 'dist/brick'));
});
