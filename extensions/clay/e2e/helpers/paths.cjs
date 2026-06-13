const { dirname, join } = require('node:path');

const e2eRoot = join(__dirname, '..');

module.exports = {
  extensionRoot: join(e2eRoot, '..'),
  fixtureRoot: join(e2eRoot, 'fixtures', 'sample-brick'),
  fixtureMainDart: join(e2eRoot, 'fixtures', 'sample-brick', 'reference', 'lib', 'main.dart'),
  fixtureWorkspaceFile: join(
    e2eRoot,
    'fixtures',
    'sample-brick',
    'sample-brick.code-workspace',
  ),
  grammarPath: join(e2eRoot, '..', 'syntaxes', 'clay.tmLanguage.json'),
};
