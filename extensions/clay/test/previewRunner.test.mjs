import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const { CLAY_CLI_SCRIPT_RELATIVE_PATH } = require('./out/workspaceClayScript.cjs');
const { runTemplatePreview } = require('./out/previewRunner.cjs');

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = join(extensionRoot, '..', '..');
const clayScriptPath = join(repoRoot, CLAY_CLI_SCRIPT_RELATIVE_PATH);

function createPreviewFixture() {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-preview-runner-'));
  const referenceDir = join(tempDir, 'reference');
  const nestedDir = join(referenceDir, 'lib');
  mkdirSync(nestedDir, { recursive: true });

  writeFileSync(
    join(tempDir, 'brick-gen.json'),
    JSON.stringify({ reference: 'reference', target: 'brick/__brick__' }),
  );

  const filePath = join(nestedDir, 'main.dart');
  writeFileSync(
    filePath,
    [
      'void main() {',
      '  /*remove-start*/',
      '  print("scaffold");',
      '  /*remove-end*/',
      '}',
      '',
    ].join('\n'),
  );

  return { tempDir, filePath };
}

test('runTemplatePreview transforms a reference file via workspace dart run', async () => {
  const fixture = createPreviewFixture();
  try {
    const scope = {
      projectRoot: fixture.tempDir,
      configPath: join(fixture.tempDir, 'brick-gen.json'),
      referenceDir: join(fixture.tempDir, 'reference'),
      targetDir: join(fixture.tempDir, 'brick', '__brick__'),
    };

    const output = await runTemplatePreview({
      scope,
      filePath: fixture.filePath,
      cli: { executable: 'dart', prefixArgs: ['run', clayScriptPath] },
    });

    assert.match(output, /void main\(\) \{/);
    assert.doesNotMatch(output, /remove-start/);
    assert.doesNotMatch(output, /print\("scaffold"\)/);
  } finally {
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('runTemplatePreview surfaces CLI stderr on failure', async () => {
  const fixture = createPreviewFixture();
  try {
    await assert.rejects(
      () =>
        runTemplatePreview({
          scope: {
            projectRoot: fixture.tempDir,
            configPath: join(fixture.tempDir, 'brick-gen.json'),
            referenceDir: join(fixture.tempDir, 'reference'),
            targetDir: join(fixture.tempDir, 'brick', '__brick__'),
          },
          filePath: join(fixture.tempDir, 'reference', 'missing.dart'),
          cli: { executable: 'dart', prefixArgs: ['run', clayScriptPath] },
        }),
      /not found|outside|does not exist/i,
    );
  } finally {
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});
