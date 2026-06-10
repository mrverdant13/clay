import * as vscode from 'vscode';

import { readAnnotationConfig } from './annotationConfig';
import { refreshInsertHighlights } from './insertHighlighting';
import { refreshMustacheHighlights } from './mustacheHighlighting';
import { refreshPartialHighlights } from './partialHighlighting';
import { refreshRemoveHighlights } from './removeHighlighting';
import { refreshReplaceHighlights } from './replaceHighlighting';
import { refreshSpacingHighlights } from './spacingHighlighting';

const DOCUMENT_CHANGE_DEBOUNCE_MS = 150;

function refreshAnnotationHighlights(editor: vscode.TextEditor | undefined): void {
  const config = readAnnotationConfig();
  refreshRemoveHighlights(editor, config);
  refreshReplaceHighlights(editor, config);
  refreshInsertHighlights(editor, config);
  refreshPartialHighlights(editor, config);
  refreshMustacheHighlights(editor, config);
  refreshSpacingHighlights(editor, config);
}

function refreshAllVisibleEditors(): void {
  for (const editor of vscode.window.visibleTextEditors) {
    refreshAnnotationHighlights(editor);
  }
}

function refreshEditorsForDocument(document: vscode.TextDocument): void {
  for (const editor of vscode.window.visibleTextEditors) {
    if (editor.document === document) {
      refreshAnnotationHighlights(editor);
    }
  }
}

export function registerAnnotationHighlighting(context: vscode.ExtensionContext): void {
  const pendingDocumentRefreshes = new Map<string, ReturnType<typeof setTimeout>>();

  function scheduleRefreshEditorsForDocument(document: vscode.TextDocument): void {
    const key = document.uri.toString();
    const pending = pendingDocumentRefreshes.get(key);
    if (pending !== undefined) {
      clearTimeout(pending);
    }

    pendingDocumentRefreshes.set(
      key,
      setTimeout(() => {
        pendingDocumentRefreshes.delete(key);
        refreshEditorsForDocument(document);
      }, DOCUMENT_CHANGE_DEBOUNCE_MS),
    );
  }

  refreshAllVisibleEditors();

  context.subscriptions.push(
    vscode.window.onDidChangeActiveTextEditor(refreshAnnotationHighlights),
    vscode.workspace.onDidChangeTextDocument((event) => {
      scheduleRefreshEditorsForDocument(event.document);
    }),
    vscode.workspace.onDidOpenTextDocument((document) => {
      refreshEditorsForDocument(document);
    }),
    {
      dispose() {
        for (const timer of pendingDocumentRefreshes.values()) {
          clearTimeout(timer);
        }
        pendingDocumentRefreshes.clear();
      },
    },
  );
}
