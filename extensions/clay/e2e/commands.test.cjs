const assert = require('node:assert/strict');

const vscode = require('vscode');

suite('Preview commands', () => {
  test('registers clay preview commands in the Extension Host', async () => {
    const commands = await vscode.commands.getCommands(true);

    assert.ok(
      commands.includes('clay.previewTemplate'),
      'clay.previewTemplate should be registered',
    );
    assert.ok(
      commands.includes('clay.previewGenerated'),
      'clay.previewGenerated should be registered',
    );
  });
});
