import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import { createMockEditor, installVscodeMock } from './vscode-mock.mjs';

const { mockVscode } = installVscodeMock();

const require = createRequire(import.meta.url);
const { registerAnnotationHighlighting } = require('./out/annotationHighlighting.cjs');

test('registerAnnotationHighlighting refreshes visible editors on configuration changes', () => {
  const editor = createMockEditor('/*insert-start*/x/*insert-end*/');
  mockVscode.window.visibleTextEditors = [editor];

  let configHandler;
  mockVscode.workspace.onDidChangeConfiguration = (handler) => {
    configHandler = handler;
    return { dispose: () => {} };
  };
  mockVscode.workspace.onDidChangeTextDocument = () => ({ dispose: () => {} });
  mockVscode.workspace.onDidOpenTextDocument = () => ({ dispose: () => {} });
  mockVscode.window.onDidChangeActiveTextEditor = () => ({ dispose: () => {} });

  const subscriptions = [];
  registerAnnotationHighlighting({ subscriptions });

  assert.ok(configHandler, 'configuration listener was not registered');
  editor.decorationCalls.length = 0;

  configHandler({ affectsConfiguration: (section) => section === 'clay.colors' });
  assert.ok(editor.decorationCalls.length > 0, 'expected highlight refresh after config change');
});

test('registerAnnotationHighlighting debounces document change refreshes', async () => {
  const editor = createMockEditor('/*remove-start*/x/*remove-end*/');
  const document = editor.document;

  let documentHandler;
  mockVscode.window.visibleTextEditors = [editor];
  mockVscode.workspace.onDidChangeTextDocument = (handler) => {
    documentHandler = handler;
    return { dispose: () => {} };
  };
  mockVscode.workspace.onDidChangeConfiguration = () => ({ dispose: () => {} });
  mockVscode.workspace.onDidOpenTextDocument = () => ({ dispose: () => {} });
  mockVscode.window.onDidChangeActiveTextEditor = () => ({ dispose: () => {} });

  const subscriptions = [];
  registerAnnotationHighlighting({ subscriptions });
  assert.ok(documentHandler, 'document listener was not registered');

  editor.decorationCalls.length = 0;
  documentHandler({ document });
  assert.equal(editor.decorationCalls.length, 0, 'refresh should be debounced');

  await new Promise((resolve) => setTimeout(resolve, 200));
  assert.ok(editor.decorationCalls.length > 0, 'expected debounced highlight refresh');
});
