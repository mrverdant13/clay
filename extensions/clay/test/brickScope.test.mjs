import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(import.meta.url);

const {
  collectConfigSearchPaths,
  isPathWithinDirectory,
  findBrickScopeForFile,
} = require('./out/brickScope.cjs');

function createScopeFixture({
  reference = 'reference',
  target = 'brick/__brick__',
} = {}) {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-brick-scope-'));
  const referenceDir = join(tempDir, reference);
  const nestedDir = join(referenceDir, 'lib', 'src');
  mkdirSync(nestedDir, { recursive: true });

  writeFileSync(
    join(tempDir, 'brick-gen.json'),
    JSON.stringify({ reference, target }),
  );

  const filePath = join(nestedDir, 'main.dart');
  writeFileSync(filePath, 'void main() {}\n');

  return { tempDir, referenceDir, nestedDir, filePath };
}

test('collectConfigSearchPaths walks up to the filesystem root', () => {
  const startDir = join('/project', 'reference', 'lib');
  const paths = collectConfigSearchPaths(startDir);

  assert.deepEqual(paths, [
    join('/project', 'reference', 'lib', 'brick-gen.json'),
    join('/project', 'reference', 'brick-gen.json'),
    join('/project', 'brick-gen.json'),
    join('/', 'brick-gen.json'),
  ]);
});

test('isPathWithinDirectory accepts nested files and rejects siblings', () => {
  const referenceDir = join('/project', 'reference');

  assert.equal(
    isPathWithinDirectory(join(referenceDir, 'lib', 'main.dart'), referenceDir),
    true,
  );
  assert.equal(isPathWithinDirectory(referenceDir, referenceDir), false);
  assert.equal(
    isPathWithinDirectory(join('/project', 'other', 'main.dart'), referenceDir),
    false,
  );
});

test('isPathWithinDirectory accepts directories whose names start with dots', () => {
  const referenceDir = join('/project', 'reference');

  assert.equal(
    isPathWithinDirectory(join(referenceDir, '..cache', 'file.txt'), referenceDir),
    true,
  );
});

test('findBrickScopeForFile discovers config in the project root', () => {
  const fixture = createScopeFixture();
  try {
    const scope = findBrickScopeForFile(fixture.filePath);

    assert.ok(scope);
    assert.equal(scope.projectRoot, fixture.tempDir);
    assert.equal(scope.configPath, join(fixture.tempDir, 'brick-gen.json'));
    assert.equal(scope.referenceDir, fixture.referenceDir);
    assert.equal(scope.targetDir, join(fixture.tempDir, 'brick', '__brick__'));
  } finally {
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('findBrickScopeForFile discovers nested config directories', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-brick-scope-'));
  try {
    const scopeDir = join(tempDir, 'scopes', 'demo');
    const referenceDir = join(scopeDir, 'refs');
    const filePath = join(referenceDir, 'app.dart');
    mkdirSync(referenceDir, { recursive: true });
    writeFileSync(filePath, 'void main() {}\n');
    writeFileSync(
      join(scopeDir, 'brick-gen.json'),
      JSON.stringify({ reference: 'refs', target: 'out/template' }),
    );

    const scope = findBrickScopeForFile(filePath);

    assert.ok(scope);
    assert.equal(scope.projectRoot, scopeDir);
    assert.equal(scope.referenceDir, referenceDir);
    assert.equal(scope.targetDir, join(scopeDir, 'out/template'));
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test('findBrickScopeForFile skips nested config when file is outside its reference', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-brick-scope-'));
  try {
    const parentReference = join(tempDir, 'reference');
    const nestedScopeDir = join(tempDir, 'scopes', 'demo');
    const nestedReference = join(nestedScopeDir, 'refs');
    const filePath = join(parentReference, 'lib', 'main.dart');
    mkdirSync(join(parentReference, 'lib'), { recursive: true });
    mkdirSync(nestedReference, { recursive: true });
    writeFileSync(filePath, 'void main() {}\n');

    writeFileSync(
      join(tempDir, 'brick-gen.json'),
      JSON.stringify({ reference: 'reference', target: 'brick/__brick__' }),
    );
    writeFileSync(
      join(nestedScopeDir, 'brick-gen.json'),
      JSON.stringify({ reference: 'refs', target: 'out/template' }),
    );

    const scope = findBrickScopeForFile(filePath);

    assert.ok(scope);
    assert.equal(scope.projectRoot, tempDir);
    assert.equal(scope.referenceDir, parentReference);
    assert.equal(scope.targetDir, join(tempDir, 'brick', '__brick__'));
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test('findBrickScopeForFile returns undefined when file is outside reference', () => {
  const fixture = createScopeFixture();
  try {
    const outsideFile = join(fixture.tempDir, 'notes.txt');
    writeFileSync(outsideFile, 'outside reference\n');

    assert.equal(findBrickScopeForFile(outsideFile), undefined);
  } finally {
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('findBrickScopeForFile returns undefined when no config exists', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-brick-scope-'));
  try {
    const filePath = join(tempDir, 'orphan.dart');
    writeFileSync(filePath, 'void main() {}\n');

    assert.equal(findBrickScopeForFile(filePath), undefined);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});
