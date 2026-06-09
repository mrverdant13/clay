import * as vscode from 'vscode';

/**
 * Activates the Clay extension.
 *
 * Annotation marker syntax highlighting is contributed via TextMate grammar
 * injection into comment regions.
 */
export function activate(context: vscode.ExtensionContext): void {
  // Additional features register via context.subscriptions in follow-up work.
  void context;
}

export function deactivate(): void {
  // Subscriptions dispose via context.subscriptions.
}
