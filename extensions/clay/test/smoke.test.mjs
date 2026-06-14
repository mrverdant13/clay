import assert from 'node:assert/strict';
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
