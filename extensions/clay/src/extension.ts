import * as vscode from 'vscode';

import { registerAnnotationHighlighting } from './annotationHighlighting';
import { registerBlockFolding } from './blockFolding';
import { registerInsertHighlighting } from './insertHighlighting';
import { registerMustacheHighlighting } from './mustacheHighlighting';
import { registerPartialHighlighting } from './partialHighlighting';
import { registerRemoveHighlighting } from './removeHighlighting';
import { registerReplaceHighlighting } from './replaceHighlighting';
import { registerSpacingHighlighting } from './spacingHighlighting';

/**
 * Activates the Clay extension.
 *
 * Annotation marker syntax highlighting is contributed via TextMate grammar
 * injection into comment regions. Annotation regions are tinted programmatically
 * so colors apply reliably inside comment regions.
 */
export function activate(context: vscode.ExtensionContext): void {
  registerBlockFolding(context);
  registerRemoveHighlighting(context);
  registerReplaceHighlighting(context);
  registerInsertHighlighting(context);
  registerPartialHighlighting(context);
  registerMustacheHighlighting(context);
  registerSpacingHighlighting(context);
  registerAnnotationHighlighting(context);
}

export function deactivate(): void {
  // Subscriptions dispose via context.subscriptions.
}
