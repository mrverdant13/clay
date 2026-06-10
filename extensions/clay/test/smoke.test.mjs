import assert from 'node:assert/strict';
import { execSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { test } from 'node:test';

const extensionRoot = join(dirname(fileURLToPath(import.meta.url)), '..');

/** @type {Record<string, unknown>} */
const grammar = JSON.parse(
  readFileSync(join(extensionRoot, 'syntaxes/clay.tmLanguage.json'), 'utf8'),
);

const expectedMarkerKeys = [
  'dart-remove',
  'dart-replace',
  'dart-insert',
  'dart-drop',
  'dart-partial',
  'dart-spacing',
  'dart-mustache',
  'hash-remove',
  'hash-replace',
  'hash-insert',
  'hash-drop',
  'hash-partial',
  'hash-spacing',
  'hash-mustache',
  'html-remove',
  'html-replace',
  'html-insert',
  'html-drop',
  'html-partial',
  'html-spacing',
  'html-mustache',
];

test('grammar declares clay injection scope', () => {
  assert.equal(grammar.scopeName, 'clay.injection');
  assert.equal(grammar.injectionSelector, 'L:comment');
});

test('grammar covers all marker types in three comment flavors', () => {
  const repository = /** @type {Record<string, unknown>} */ (grammar.repository);
  for (const key of expectedMarkerKeys) {
    assert.ok(repository[key], `missing repository rule: ${key}`);
  }
});

const expectedSourceModules = [
  'annotationBlockPairing.ts',
  'annotationMarkerSets.ts',
  'annotationHighlighting.ts',
  'blockFolding.ts',
  'rangeUtils.ts',
  'brickGen.ts',
  'brickScope.ts',
  'clayCli.ts',
  'workspaceClayScript.ts',
  'previewRunner.ts',
  'previewCommand.ts',
  'mustachePatterns.ts',
  'brickVariables.ts',
  'previewFileVariables.ts',
  'previewVariableState.ts',
  'variableQuickPick.ts',
];

test('block shading and folding source modules exist', () => {
  for (const moduleName of expectedSourceModules) {
    assert.ok(
      readFileSync(join(extensionRoot, 'src', moduleName), 'utf8').length > 0,
      `missing source module: ${moduleName}`,
    );
  }
});

test('extension registers block shading and folding', () => {
  const extensionSource = readFileSync(
    join(extensionRoot, 'src/extension.ts'),
    'utf8',
  );

  const activateStart = extensionSource.indexOf(
    'export function activate(context: vscode.ExtensionContext): void {',
  );
  assert.ok(activateStart >= 0, 'activate() not found');

  const activateEnd = extensionSource.indexOf('\nexport function deactivate');
  assert.ok(activateEnd > activateStart, 'deactivate() not found');
  const activateBody = extensionSource.slice(activateStart, activateEnd);

  assert.match(activateBody, /\bregisterAnnotationHighlighting\s*\(\s*context\s*\)/);
  assert.match(activateBody, /\bregisterBlockFolding\s*\(\s*context\s*\)/);
  assert.match(activateBody, /\bregisterPreviewCommands\s*\(\s*context\s*\)/);
});

test('package.json contributes preview commands', () => {
  const manifest = JSON.parse(
    readFileSync(join(extensionRoot, 'package.json'), 'utf8'),
  );
  const commands = /** @type {Array<{ command: string }>} */ (
    manifest.contributes?.commands ?? []
  );

  assert.ok(
    commands.some((entry) => entry.command === 'clay.previewTemplate'),
    'missing clay.previewTemplate command',
  );
  assert.ok(
    commands.some((entry) => entry.command === 'clay.previewGenerated'),
    'missing clay.previewGenerated command',
  );
});

test('extension compiles', () => {
  execSync('node esbuild.mjs', { cwd: extensionRoot, stdio: 'inherit' });
});
