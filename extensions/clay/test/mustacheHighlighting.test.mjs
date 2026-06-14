import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import {
  createMockEditor,
  defaultAnnotationConfig,
  installVscodeMock,
  rangesText,
} from './vscode-mock.mjs';

installVscodeMock();

const require = createRequire(import.meta.url);
const { refreshMustacheHighlights } = require('./out/mustacheHighlighting.cjs');

test('refreshMustacheHighlights decorates mustache tags inside block comments', () => {
  const text = 'before /*{{name}}*/ after';
  const editor = createMockEditor(text);

  refreshMustacheHighlights(editor, defaultAnnotationConfig);

  assert.equal(editor.decorationCalls.length, 3);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 1), ['{{name}}']);
});

test('refreshMustacheHighlights ignores empty mustache tags', () => {
  const text = '/*{{}}*/ valid /*{{#foo}}*/';
  const editor = createMockEditor(text);

  refreshMustacheHighlights(editor, defaultAnnotationConfig);

  const tagSpans = rangesText(editor.document, editor.decorationCalls, 1);
  assert.deepEqual(tagSpans, ['{{#foo}}']);
});

test('refreshMustacheHighlights clears decorations for unsupported files', () => {
  const editor = createMockEditor('/*{{name}}*/', '/project/notes.txt');

  refreshMustacheHighlights(editor, defaultAnnotationConfig);
  assert.equal(editor.decorationCalls.length, 3);

  editor.decorationCalls.length = 0;
  refreshMustacheHighlights(editor, defaultAnnotationConfig);

  for (const call of editor.decorationCalls) {
    assert.deepEqual(call.ranges, []);
  }
});
