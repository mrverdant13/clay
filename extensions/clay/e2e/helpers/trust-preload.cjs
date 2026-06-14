/**
 * @vscode/test-electron always passes `--disable-workspace-trust`, so Restricted
 * Mode cannot be exercised via launch args alone. When CLAY_E2E_SIMULATE_UNTRUSTED
 * is set, patch the workspace trust flag before tests load the extension.
 */
if (process.env.CLAY_E2E_SIMULATE_UNTRUSTED === '1') {
  const vscode = require('vscode');

  Object.defineProperty(vscode.workspace, 'isTrusted', {
    configurable: true,
    get() {
      return false;
    },
  });
}
