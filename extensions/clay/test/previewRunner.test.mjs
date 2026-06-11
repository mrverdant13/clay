import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const { CLAY_CLI_SCRIPT_RELATIVE_PATH } = require('./out/workspaceClayScript.cjs');
const { runGeneratedPreview, runTemplatePreview } = require('./out/previewRunner.cjs');

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');
const repoRoot = join(extensionRoot, '..', '..');
const clayScriptPath = join(repoRoot, CLAY_CLI_SCRIPT_RELATIVE_PATH);

function createScope(tempDir) {
  return {
    projectRoot: tempDir,
    configPath: join(tempDir, 'clay.yaml'),
    scopeName: join(tempDir, 'clay.yaml'),
    referenceDir: join(tempDir, 'reference'),
    targetDir: join(tempDir, 'brick', '__brick__'),
    brickYamlPath: join(tempDir, 'brick', 'brick.yaml'),
  };
}

function createPreviewFixture({
  replacements = [],
  fileContent = [
    'void main() {',
    '  /*remove-start*/',
    '  print("scaffold");',
    '  /*remove-end*/',
    '}',
    '',
  ].join('\n'),
} = {}) {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-preview-runner-'));
  const referenceDir = join(tempDir, 'reference');
  const nestedDir = join(referenceDir, 'lib');
  mkdirSync(nestedDir, { recursive: true });

  const replacementsYaml =
    replacements.length === 0
      ? ''
      : `replacements:\n${replacements
          .map(
            (entry) =>
              `  - from: ${entry.from}\n    to: ${JSON.stringify(entry.to)}`,
          )
          .join('\n')}\n`;

  writeFileSync(
    join(tempDir, 'clay.yaml'),
    `reference: reference
target: brick/__brick__
${replacementsYaml}`,
  );

  const filePath = join(nestedDir, 'main.dart');
  writeFileSync(filePath, fileContent);

  return { tempDir, filePath };
}

test('runTemplatePreview transforms a reference file via workspace dart run', async () => {
  const fixture = createPreviewFixture();
  try {
    const output = await runTemplatePreview({
      scope: createScope(fixture.tempDir),
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
          scope: createScope(fixture.tempDir),
          filePath: join(fixture.tempDir, 'reference', 'missing.dart'),
          cli: { executable: 'dart', prefixArgs: ['run', clayScriptPath] },
        }),
      /not found|outside|does not exist/i,
    );
  } finally {
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('runGeneratedPreview renders Mustache variables via workspace dart run', async () => {
  const fixture = createPreviewFixture({
    replacements: [
      {
        from: 'Widget',
        to: '{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}{{^use_riverpod}}StatelessWidget{{/use_riverpod}}',
      },
    ],
    fileContent: 'class App extends Widget {}\n',
  });
  try {
    const output = await runGeneratedPreview({
      scope: createScope(fixture.tempDir),
      filePath: fixture.filePath,
      cli: { executable: 'dart', prefixArgs: ['run', clayScriptPath] },
      vars: { use_riverpod: true },
    });

    assert.match(output, /ConsumerWidget/);
    assert.doesNotMatch(output, /StatelessWidget/);
    assert.doesNotMatch(output, /use_riverpod/);
  } finally {
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});
