import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

import { createMockDocument, installVscodeMock } from './vscode-mock.mjs';

installVscodeMock();

const require = createRequire(import.meta.url);
const { isSupportedReferenceFile } = require('./out/supportedFiles.cjs');

test('isSupportedReferenceFile accepts common reference extensions', () => {
  for (const fileName of [
    '/project/lib/main.dart',
    '/project/bin/run.sh',
    '/project/clay.yaml',
    '/project/config.yml',
    '/project/web/index.html',
    '/project/web/page.htm',
    '/project/tool/schema.xml',
    '/project/docs/guide.md',
    '/project/docs/guide.markdown',
  ]) {
    assert.ok(
      isSupportedReferenceFile(createMockDocument('', fileName)),
      `expected supported: ${fileName}`,
    );
  }
});

test('isSupportedReferenceFile accepts ignore-style basenames', () => {
  for (const fileName of ['/project/.gitignore', '/project/.dockerignore']) {
    assert.ok(isSupportedReferenceFile(createMockDocument('', fileName)));
  }
});

test('isSupportedReferenceFile rejects unsupported files', () => {
  assert.equal(isSupportedReferenceFile(createMockDocument('', '/project/README.txt')), false);
  assert.equal(isSupportedReferenceFile(createMockDocument('', '/project/Cargo.toml')), false);
});
