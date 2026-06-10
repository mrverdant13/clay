import * as path from 'node:path';

import * as vscode from 'vscode';

import { findBrickScopeForFile } from './brickScope';
import { resolveClayCli } from './clayCli';
import { runTemplatePreview } from './previewRunner';
import { isSupportedReferenceFile } from './supportedFiles';

export const PREVIEW_TEMPLATE_COMMAND_ID = 'clay.previewTemplate';

/** Registers the template preview command. */
export function registerPreviewTemplateCommand(
  context: vscode.ExtensionContext,
): void {
  context.subscriptions.push(
    vscode.commands.registerCommand(
      PREVIEW_TEMPLATE_COMMAND_ID,
      async (uri?: vscode.Uri) => {
        await previewTemplateOutput(uri);
      },
    ),
  );
}

async function previewTemplateOutput(uri?: vscode.Uri): Promise<void> {
  const document = await resolveTargetDocument(uri);
  if (!document) {
    return;
  }

  if (!isSupportedReferenceFile(document)) {
    void vscode.window.showWarningMessage(
      'Clay preview is only available for supported reference files.',
    );
    return;
  }

  const scope = findBrickScopeForFile(document.fileName);
  if (!scope) {
    void vscode.window.showWarningMessage(
      'Could not find a brick scope (brick-gen.json) for this file.',
    );
    return;
  }

  let cli;
  try {
    cli = await resolveClayCli();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    void vscode.window.showErrorMessage(message);
    return;
  }

  await vscode.window.withProgress(
    {
      location: vscode.ProgressLocation.Notification,
      title: 'Generating template preview…',
      cancellable: false,
    },
    async () => {
      try {
        const previewContent = await runTemplatePreview({
          scope,
          filePath: document.fileName,
          cli,
        });
        await openPreviewDiff(document, previewContent);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        void vscode.window.showErrorMessage(`Preview failed: ${message}`);
      }
    },
  );
}

async function resolveTargetDocument(
  uri?: vscode.Uri,
): Promise<vscode.TextDocument | undefined> {
  if (uri) {
    return vscode.workspace.openTextDocument(uri);
  }

  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    void vscode.window.showWarningMessage('Open a reference file to preview.');
    return undefined;
  }

  return editor.document;
}

async function openPreviewDiff(
  original: vscode.TextDocument,
  previewContent: string,
): Promise<void> {
  const previewDocument = await vscode.workspace.openTextDocument({
    content: previewContent,
    language: original.languageId,
  });
  const title = `Template preview: ${path.basename(original.fileName)}`;
  await vscode.commands.executeCommand(
    'vscode.diff',
    original.uri,
    previewDocument.uri,
    title,
  );
}
