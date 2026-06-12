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
const { refreshInsertHighlights } = require('./out/insertHighlighting.cjs');
const { refreshRemoveHighlights } = require('./out/removeHighlighting.cjs');
const { refreshReplaceHighlights } = require('./out/replaceHighlighting.cjs');
const { refreshPartialHighlights } = require('./out/partialHighlighting.cjs');
const { refreshSpacingHighlights } = require('./out/spacingHighlighting.cjs');

test('refreshInsertHighlights shades insert interiors and boundary markers', () => {
  const text = 'before /*insert-start*/added/*insert-end*/ after';
  const editor = createMockEditor(text);

  refreshInsertHighlights(editor, defaultAnnotationConfig);

  assert.equal(editor.decorationCalls.length, 2);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 0), [
    '/*insert-start*/',
    '/*insert-end*/',
  ]);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 1), ['added']);
});

test('refreshRemoveHighlights shades remove blocks and drop tails', () => {
  const text = '/*remove-start*/gone/*remove-end*/ prefix #drop# trailing';
  const editor = createMockEditor(text, '/project/lib/main.dart');

  refreshRemoveHighlights(editor, defaultAnnotationConfig);

  assert.equal(editor.decorationCalls.length, 2);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 0), [
    '/*remove-start*/',
    '/*remove-end*/',
    '#drop#',
  ]);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 1), [
    'gone',
    ' trailing',
  ]);
});

test('refreshReplaceHighlights separates original and replacement regions', () => {
  const text = [
    '/*replace-start*/',
    'old',
    '/*with*/',
    'new',
    '/*replace-end*/',
  ].join('\n');
  const editor = createMockEditor(text);

  refreshReplaceHighlights(editor, defaultAnnotationConfig);

  assert.equal(editor.decorationCalls.length, 4);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 2), ['\nold\n']);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 3), ['\nnew\n']);
  assert.ok(
    rangesText(editor.document, editor.decorationCalls, 1).some((span) => span.includes('with')),
  );
});

test('refreshPartialHighlights shades named partial payloads', () => {
  const text = '/*partial v header*/payload/*partial ^ header*/';
  const editor = createMockEditor(text);

  refreshPartialHighlights(editor, defaultAnnotationConfig);

  assert.equal(editor.decorationCalls.length, 2);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 1), ['payload']);
});

test('refreshSpacingHighlights marks spacing-group comments', () => {
  const text = 'x /*w w*/ y #w w# z <!--w w-->';
  const editor = createMockEditor(text);

  refreshSpacingHighlights(editor, defaultAnnotationConfig);

  assert.equal(editor.decorationCalls.length, 1);
  assert.deepEqual(rangesText(editor.document, editor.decorationCalls, 0), [
    '/*w w*/',
    '#w w#',
    '<!--w w-->',
  ]);
});

test('highlight refresh clears decorations for unsupported files', () => {
  const editor = createMockEditor('/*insert-start*/x/*insert-end*/', '/project/README.txt');

  refreshInsertHighlights(editor, defaultAnnotationConfig);

  assert.equal(editor.decorationCalls.length, 2);
  assert.equal(editor.decorationCalls[0].ranges.length, 0);
  assert.equal(editor.decorationCalls[1].ranges.length, 0);
});
