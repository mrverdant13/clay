const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { dirname, join } = require('node:path');

const vscodeOniguruma = require('vscode-oniguruma');
const { Registry } = require('vscode-textmate');

const { grammarPath } = require('./helpers/paths.cjs');

const onigurumaWasm = join(
  dirname(require.resolve('vscode-oniguruma')),
  'onig.wasm',
);

async function createClayGrammarRegistry() {
  await vscodeOniguruma.loadWASM(readFileSync(onigurumaWasm));

  const registry = new Registry({
    onigLib: Promise.resolve(vscodeOniguruma),
    theme: { name: 'empty', settings: [] },
    loadGrammar: async (scopeName) => {
      if (scopeName !== 'clay.injection') {
        return null;
      }
      return JSON.parse(readFileSync(grammarPath, 'utf8'));
    },
  });

  return registry.loadGrammar('clay.injection');
}

suite('Grammar injection', () => {
  test('clay.tmLanguage.json assigns remove scopes to dart block markers', async () => {
    const grammar = await createClayGrammarRegistry();
    assert.ok(grammar, 'expected clay.injection grammar to load');

    const line = '  /*remove-start*/';
    const { tokens } = grammar.tokenizeLine(line, null);
    const scopes = tokens.flatMap((token) => token.scopes);

    assert.ok(
      scopes.some((scope) => scope.includes('keyword.annotation.clay.remove')),
      `expected remove scope in ${JSON.stringify(scopes)}`,
    );
  });

  test('clay.tmLanguage.json assigns insert scopes to dart block markers', async () => {
    const grammar = await createClayGrammarRegistry();
    assert.ok(grammar, 'expected clay.injection grammar to load');

    const line = '  /*insert-start*/';
    const { tokens } = grammar.tokenizeLine(line, null);
    const scopes = tokens.flatMap((token) => token.scopes);

    assert.ok(
      scopes.some((scope) => scope.includes('keyword.annotation.clay.insert')),
      `expected insert scope in ${JSON.stringify(scopes)}`,
    );
  });
});
