import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
import { test } from 'node:test';

const require = createRequire(import.meta.url);

const {
  DEFAULT_CLAY_CONSTRAINT,
  assertClayConfigCompatibleWithCli,
  formatClayIncompatibleMessage,
  isClayConfigCompatibleWithCliVersion,
  validateClayVersionConstraint,
} = require('./out/clayCompatibility.cjs');
const { parseClayConfig } = require('./out/clayConfig.cjs');

function configWithClayConstraint(constraint) {
  return parseClayConfig(`environment:\n  clay: ${constraint}\n`);
}

test('validateClayVersionConstraint accepts any and valid semver ranges', () => {
  assert.doesNotThrow(() => validateClayVersionConstraint(DEFAULT_CLAY_CONSTRAINT));
  assert.doesNotThrow(() => validateClayVersionConstraint('^0.0.1-dev.1'));
});

test('validateClayVersionConstraint rejects empty and invalid constraints', () => {
  assert.throws(
    () => validateClayVersionConstraint(''),
    /environment\.clay must not be empty/,
  );
  assert.throws(
    () => validateClayVersionConstraint('not-a-version'),
    /environment\.clay must be a valid semver constraint/,
  );
});

test('isClayConfigCompatibleWithCliVersion treats any as satisfied', () => {
  const config = parseClayConfig('');
  assert.equal(isClayConfigCompatibleWithCliVersion(config, '0.0.1-dev.1'), true);
});

test('isClayConfigCompatibleWithCliVersion checks satisfied and unsatisfied ranges', () => {
  const compatible = configWithClayConstraint('^0.0.1-dev.1');
  const incompatible = configWithClayConstraint('^99.0.0');

  assert.equal(isClayConfigCompatibleWithCliVersion(compatible, '0.0.1-dev.1'), true);
  assert.equal(isClayConfigCompatibleWithCliVersion(incompatible, '0.0.1-dev.1'), false);
});

test('assertClayConfigCompatibleWithCli throws an actionable message', () => {
  const config = configWithClayConstraint('^99.0.0');

  assert.throws(
    () => assertClayConfigCompatibleWithCli(config, '0.0.1-dev.1'),
    (error) => {
      assert.equal(
        error.message,
        formatClayIncompatibleMessage('0.0.1-dev.1', '^99.0.0'),
      );
      return true;
    },
  );
});

test('formatClayIncompatibleMessage matches the Clay CLI wording', () => {
  assert.equal(
    formatClayIncompatibleMessage('0.0.1-dev.1', '^99.0.0'),
    'The current clay version is 0.0.1-dev.1.\nThis project requires clay version ^99.0.0.',
  );
});
