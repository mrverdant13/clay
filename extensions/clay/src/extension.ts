import * as vscode from 'vscode';

/** Activates the Clay extension. */
export function activate(context: vscode.ExtensionContext): void {
  // Scaffold entrypoint; features register via context.subscriptions later.
  void context;
}

export function deactivate(): void {
  // Subscriptions dispose via context.subscriptions.
}
