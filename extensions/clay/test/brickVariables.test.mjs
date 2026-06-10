import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const { loadBrickVariables, formatVarsForCli } = require('./out/brickVariables.cjs');

test('loadBrickVariables returns an empty list when brick.yaml is missing', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-brick-vars-'));
  try {
    assert.deepEqual(loadBrickVariables(join(tempDir, 'brick.yaml')), []);
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test('loadBrickVariables parses Mason variable definitions', () => {
  const tempDir = mkdtempSync(join(tmpdir(), 'clay-brick-vars-'));
  try {
    const brickYamlPath = join(tempDir, 'brick.yaml');
    writeFileSync(
      brickYamlPath,
      [
        'name: demo',
        'vars:',
        '  use_riverpod:',
        '    type: boolean',
        '    default: true',
        '    description: Use Riverpod',
        '  platform:',
        '    type: enum',
        '    values:',
        '      - ios',
        '      - android',
        '    default: ios',
        '  title:',
        '    type: string',
        '    prompt: App title',
        '    default: "`My App`"',
      ].join('\n'),
    );

    const variables = loadBrickVariables(brickYamlPath);

    assert.equal(variables.length, 3);
    assert.deepEqual(variables[0], {
      name: 'use_riverpod',
      type: 'boolean',
      description: 'Use Riverpod',
      prompt: undefined,
      default: true,
      values: undefined,
    });
    assert.deepEqual(variables[1], {
      name: 'platform',
      type: 'enum',
      description: undefined,
      prompt: undefined,
      default: 'ios',
      values: ['ios', 'android'],
    });
    assert.equal(variables[2].name, 'title');
    assert.equal(variables[2].default, 'My App');
  } finally {
    rmSync(tempDir, { recursive: true, force: true });
  }
});

test('formatVarsForCli serializes boolean and string values', () => {
  assert.equal(
    formatVarsForCli({ use_riverpod: true, title: 'Demo' }),
    'use_riverpod=true,title=Demo',
  );
});

test('formatVarsForCli rejects comma-containing string values', () => {
  assert.throws(
    () => formatVarsForCli({ title: 'Hello, world' }),
    /cannot contain commas/i,
  );
});
