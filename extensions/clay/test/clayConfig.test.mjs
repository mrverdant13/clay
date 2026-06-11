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
  applyClayReplacements,
  parseClayConfig,
  loadClayConfig,
  resolvePathFromProjectRoot,
  resolveBrickYamlPath,
  resolveReferencePath,
  resolveTargetPath,
} = require('./out/clayConfig.cjs');

test('parseClayConfig applies defaults for omitted path fields', () => {
  const config = parseClayConfig('');

  assert.equal(config.reference, DEFAULT_REFERENCE_PATH);
  assert.equal(config.target, DEFAULT_TARGET_PATH);
  assert.deepEqual(config.ignore, []);
  assert.deepEqual(config.replacements, []);
});

test('parseClayConfig reads explicit path fields', () => {
  const config = parseClayConfig(`
reference: src/ref
target: out/template
ignore:
  - "*.png"
`);

  assert.equal(config.reference, 'src/ref');
  assert.equal(config.target, 'out/template');
  assert.deepEqual(config.ignore, ['*.png']);
});

test('parseClayConfig falls back to defaults for unexpected field types', () => {
  const config = parseClayConfig(`
reference: 42
target:
  - out/template
ignore: "*.png"
`);

  assert.equal(config.reference, DEFAULT_REFERENCE_PATH);
  assert.equal(config.target, DEFAULT_TARGET_PATH);
  assert.deepEqual(config.ignore, []);
});

test('parseClayConfig keeps only string entries in ignore arrays', () => {
  const config = parseClayConfig(`
ignore:
  - "*.png"
  - 7
  - null
  - "*.jpg"
`);

  assert.deepEqual(config.ignore, ['*.png', '*.jpg']);
});

test('loadClayConfig reads from disk', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-config-'));
  try {
    const configPath = join(tempDir, 'clay.yaml');
    writeFileSync(
      configPath,
      `reference: refs/main
target: dist/brick
`,
    );

    const config = loadClayConfig(configPath);
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
  const config = parseClayConfig(`
reference: refs/main
target: dist/brick
`);

  assert.equal(resolveReferencePath(projectRoot, config), join(projectRoot, 'refs/main'));
  assert.equal(resolveTargetPath(projectRoot, config), join(projectRoot, 'dist/brick'));
});

test('parseClayConfig reads replacement entries', () => {
  const config = parseClayConfig(`
replacements:
  - from: Widget
    to: "{{name}}"
  - from:
      pattern: App
      dotAll: true
    to: My\${1}
`);

  assert.equal(config.replacements.length, 2);
  assert.equal(config.replacements[0].to, '{{name}}');
  assert.match(config.replacements[0].from.source, /Widget/);
  assert.equal(config.replacements[1].from.flags.includes('s'), true);
});

test('applyClayReplacements applies config replacements in order', () => {
  const config = parseClayConfig(`
replacements:
  - from: Widget
    to: "{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}"
`);

  const output = applyClayReplacements('class App extends Widget {}', config.replacements);
  assert.match(output, /use_riverpod/);
});

test('applyClayReplacements rejects out-of-range capture group references', () => {
  const config = parseClayConfig(`
replacements:
  - from: (Widget)
    to: Prefix\${2}Suffix
`);

  assert.throws(
    () => applyClayReplacements('class App extends Widget {}', config.replacements),
    /capture group \$\{2\}/,
  );
});

test('resolveBrickYamlPath resolves adjacent to the target directory', () => {
  const projectRoot = join(tmpdir(), 'project');
  const config = parseClayConfig('target: brick/__brick__');

  assert.equal(
    resolveBrickYamlPath(projectRoot, config),
    join(projectRoot, 'brick', 'brick.yaml'),
  );
});
