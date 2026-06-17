import assert from 'node:assert/strict';
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

import {
  createMockEditor,
  installVscodeMock,
} from './vscode-mock.mjs';

const {
  configuration,
  errorMessages,
  executedCommands,
  mockVscode,
  openedDocuments,
  registeredCommands,
  warningMessages,
} = installVscodeMock();

const require = createRequire(import.meta.url);
const {
  setClayCliExecFileForTests,
} = require('./out/clayCli.cjs');
const {
  setPreviewRunnerExecFileForTests,
} = require('./out/previewRunner.cjs');
const {
  PREVIEW_GENERATED_COMMAND_ID,
  PREVIEW_TEMPLATE_COMMAND_ID,
  ensureWorkspaceTrustedForPreview,
  registerPreviewCommands,
} = require('./out/previewCommand.cjs');

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

registerPreviewCommands({ subscriptions: [] });

const templateHandler = registeredCommands.find(
  (entry) => entry.id === PREVIEW_TEMPLATE_COMMAND_ID,
)?.handler;
const generatedHandler = registeredCommands.find(
  (entry) => entry.id === PREVIEW_GENERATED_COMMAND_ID,
)?.handler;

assert.equal(typeof templateHandler, 'function');
assert.equal(typeof generatedHandler, 'function');

function resetMockState() {
  warningMessages.length = 0;
  errorMessages.length = 0;
  executedCommands.length = 0;
  openedDocuments.length = 0;
  configuration.clear();
  mockVscode.window.activeTextEditor = undefined;
  mockVscode.workspace.workspaceFolders = undefined;
}

function installMockClayCliSubprocesses({
  version = '0.0.1-dev.1',
  previewStdout = 'void main() {\n}\n',
} = {}) {
  setClayCliExecFileForTests(async (_executable, args) => {
    if (args.includes('--version')) {
      return { stdout: `${version}\n`, stderr: '' };
    }

    if (args.includes('preview')) {
      const error = new Error('missing file');
      error.stderr = 'Missing required --file';
      throw error;
    }

    throw new Error(`Unexpected clay CLI invocation: ${args.join(' ')}`);
  });
  setPreviewRunnerExecFileForTests(async () => ({
    stdout: previewStdout,
    stderr: '',
  }));
}

function resetMockClayCliSubprocesses() {
  setClayCliExecFileForTests();
  setPreviewRunnerExecFileForTests();
}

function createPreviewFixture({
  fileContent = [
    'void main() {',
    '  /*remove-start*/',
    '  print("scaffold");',
    '  /*remove-end*/',
    '}',
    '',
  ].join('\n'),
  clayYaml = 'reference: reference\ntarget: brick/__brick__\n',
} = {}) {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-preview-command-'));
  const referenceDir = join(tempDir, 'reference');
  const nestedDir = join(referenceDir, 'lib');
  mkdirSync(nestedDir, { recursive: true });

  writeFileSync(join(tempDir, 'clay.yaml'), clayYaml);

  const filePath = join(nestedDir, 'main.dart');
  writeFileSync(filePath, fileContent);

  return { tempDir, filePath };
}

test('preview command ids match package.json contributions', () => {
  assert.equal(PREVIEW_TEMPLATE_COMMAND_ID, 'clay.previewTemplate');
  assert.equal(PREVIEW_GENERATED_COMMAND_ID, 'clay.previewGenerated');
});

test('registerPreviewCommands wires template and generated handlers', () => {
  const commandIds = registeredCommands.map((entry) => entry.id);
  assert.deepEqual(commandIds, [
    PREVIEW_TEMPLATE_COMMAND_ID,
    PREVIEW_GENERATED_COMMAND_ID,
  ]);
});

test('template preview warns for unsupported reference files', async () => {
  resetMockState();
  mockVscode.window.activeTextEditor = createMockEditor('notes', '/project/readme.txt');

  await templateHandler();

  assert.equal(warningMessages.length, 1);
  assert.match(
    warningMessages[0],
    /Clay preview is only available for supported reference files/,
  );
  assert.equal(executedCommands.length, 0);
});

test('template preview warns when no brick scope is found', async () => {
  resetMockState();
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-preview-command-'));
  try {
    const filePath = join(tempDir, 'lib', 'main.dart');
    mkdirSync(dirname(filePath), { recursive: true });
    writeFileSync(filePath, 'void main() {}');
    mockVscode.window.activeTextEditor = createMockEditor('void main() {}', filePath);

    await templateHandler();

    assert.equal(warningMessages.length, 1);
    assert.match(
      warningMessages[0],
      /Could not find a brick scope \(clay.yaml\) for this file/,
    );
    assert.equal(executedCommands.length, 0);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test('template preview returns early when the document is not saved', async () => {
  resetMockState();
  const fixture = createPreviewFixture();
  try {
    mockVscode.window.activeTextEditor = createMockEditor(
      'void main() {}',
      fixture.filePath,
      { isDirty: true, saveResult: false },
    );

    await templateHandler();

    assert.equal(warningMessages.length, 1);
    assert.match(
      warningMessages[0],
      /Save the file before previewing template output/,
    );
    assert.equal(executedCommands.length, 0);
  } finally {
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('template preview warns when the workspace is not trusted', async () => {
  resetMockState();
  const fixture = createPreviewFixture();
  mockVscode.workspace.isTrusted = false;
  try {
    mockVscode.window.activeTextEditor = createMockEditor(
      'void main() {}',
      fixture.filePath,
    );

    await templateHandler();

    assert.equal(warningMessages.length, 1);
    assert.match(
      warningMessages[0],
      /Clay preview requires a trusted workspace/,
    );
    assert.equal(executedCommands.length, 0);
  } finally {
    mockVscode.workspace.isTrusted = true;
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('template preview opens a diff document on success', async () => {
  resetMockState();
  installMockClayCliSubprocesses({
    previewStdout: [
      'void main() {',
      '}',
      '',
    ].join('\n'),
  });
  configuration.set('clay.cliPath', '/bin/clay');

  const fileContent = [
    'void main() {',
    '  /*remove-start*/',
    '  print("scaffold");',
    '  /*remove-end*/',
    '}',
    '',
  ].join('\n');
  const fixture = createPreviewFixture({ fileContent });
  try {
    mockVscode.window.activeTextEditor = createMockEditor(
      fileContent,
      fixture.filePath,
    );

    await templateHandler();

    assert.equal(warningMessages.length, 0);

    const previewDocumentEntry = openedDocuments.find((entry) => entry.kind === 'content');
    assert.ok(previewDocumentEntry, 'expected preview content document to open');
    assert.match(previewDocumentEntry.document.getText(), /void main\(\)/);
    assert.doesNotMatch(previewDocumentEntry.document.getText(), /remove-start/);

    const diffCommand = executedCommands.find((entry) => entry.command === 'vscode.diff');
    assert.ok(diffCommand, 'expected vscode.diff command to run');
    assert.equal(diffCommand.args[0], mockVscode.window.activeTextEditor.document.uri);
    assert.equal(diffCommand.args[1], previewDocumentEntry.document.uri);
    assert.match(String(diffCommand.args[2]), /Template preview: main\.dart/);
  } finally {
    resetMockClayCliSubprocesses();
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('template preview blocks when environment.clay is not satisfied', async () => {
  resetMockState();
  installMockClayCliSubprocesses({ version: '0.0.1-dev.1' });
  configuration.set('clay.cliPath', '/bin/clay');

  const fixture = createPreviewFixture({
    clayYaml: [
      'reference: reference',
      'target: brick/__brick__',
      'environment:',
      '  clay: ^99.0.0',
      '',
    ].join('\n'),
  });
  try {
    mockVscode.window.activeTextEditor = createMockEditor(
      'void main() {}',
      fixture.filePath,
    );

    await templateHandler();

    assert.equal(warningMessages.length, 0);
    assert.equal(errorMessages.length, 1);
    assert.match(errorMessages[0], /The current clay version is/);
    assert.match(errorMessages[0], /requires clay version \^99\.0\.0/);
    assert.equal(executedCommands.length, 0);
  } finally {
    resetMockClayCliSubprocesses();
    rmSync(fixture.tempDir, { recursive: true, force: true });
  }
});

test('ensureWorkspaceTrustedForPreview returns false in Restricted Mode', () => {
  resetMockState();
  mockVscode.workspace.isTrusted = false;

  assert.equal(ensureWorkspaceTrustedForPreview(), false);
  assert.equal(warningMessages.length, 1);
  assert.match(
    warningMessages[0],
    /Clay preview requires a trusted workspace/,
  );

  mockVscode.workspace.isTrusted = true;
});
