import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const {
  runGeneratedPreview,
  runTemplatePreview,
  setPreviewRunnerExecFileForTests,
} = require('./out/previewRunner.cjs');

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

test('runTemplatePreview invokes preview with --template-only and returns stdout', async () => {
  /** @type {{ executable?: string; args?: string[] } | null} */
  let captured = null;

  setPreviewRunnerExecFileForTests(async (executable, args) => {
    captured = { executable, args };
    return { stdout: 'void main() {\n}\n', stderr: '' };
  });

  const fixture = createPreviewFixture();
  try {
    const output = await runTemplatePreview({
      scope: createScope(fixture.tempDir),
      filePath: fixture.filePath,
      cli: { executable: '/bin/clay', prefixArgs: [] },
    });

    assert.equal(output, 'void main() {\n}\n');
    assert.deepEqual(captured, {
      executable: '/bin/clay',
      args: [
        'preview',
        '--file',
        fixture.filePath,
        '--config',
        join(fixture.tempDir, 'clay.yaml'),
        '--cwd',
        fixture.tempDir,
        '--template-only',
      ],
    });
  } finally {
    setPreviewRunnerExecFileForTests();
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('runTemplatePreview surfaces CLI stderr on failure', async () => {
  setPreviewRunnerExecFileForTests(async () => {
    const error = new Error('preview failed');
    error.stderr = 'Reference file does not exist.';
    throw error;
  });

  const fixture = createPreviewFixture();
  try {
    await assert.rejects(
      () =>
        runTemplatePreview({
          scope: createScope(fixture.tempDir),
          filePath: join(fixture.tempDir, 'reference', 'missing.dart'),
          cli: { executable: '/bin/clay', prefixArgs: [] },
        }),
      /Reference file does not exist/,
    );
  } finally {
    setPreviewRunnerExecFileForTests();
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('runGeneratedPreview invokes preview with --vars and returns stdout', async () => {
  /** @type {{ executable?: string; args?: string[] } | null} */
  let captured = null;

  setPreviewRunnerExecFileForTests(async (executable, args) => {
    captured = { executable, args };
    return { stdout: 'class App extends ConsumerWidget {}\n', stderr: '' };
  });

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
      cli: { executable: '/bin/clay', prefixArgs: [] },
      vars: { use_riverpod: true },
    });

    assert.equal(output, 'class App extends ConsumerWidget {}\n');
    assert.equal(captured?.executable, '/bin/clay');
    assert.ok(captured?.args.includes('preview'));
    assert.ok(captured?.args.includes('--vars'));
    assert.match(captured?.args.join(' ') ?? '', /use_riverpod/);
  } finally {
    setPreviewRunnerExecFileForTests();
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});
