import * as path from 'node:path';

import * as vscode from 'vscode';

import { loadBrickGenConfig } from './brickGen';
import { findBrickScopeForFile } from './brickScope';
import { loadBrickVariables } from './brickVariables';
import { resolveClayCli } from './clayCli';
import { resolvePreviewVariables } from './previewFileVariables';
import {
  loadSavedPreviewVariables,
  savePreviewVariables,
} from './previewVariableState';
import { runGeneratedPreview, runTemplatePreview } from './previewRunner';
import { isSupportedReferenceFile } from './supportedFiles';
import { collectPreviewVariableValues } from './variableQuickPick';

export const PREVIEW_TEMPLATE_COMMAND_ID = 'clay.previewTemplate';
export const PREVIEW_GENERATED_COMMAND_ID = 'clay.previewGenerated';

/** Registers preview commands. */
export function registerPreviewCommands(context: vscode.ExtensionContext): void {
  context.subscriptions.push(
    vscode.commands.registerCommand(
      PREVIEW_TEMPLATE_COMMAND_ID,
      async (uri?: vscode.Uri) => {
        await previewTemplateOutput(uri);
      },
    ),
    vscode.commands.registerCommand(
      PREVIEW_GENERATED_COMMAND_ID,
      async (uri?: vscode.Uri) => {
        await previewGeneratedOutput(context, uri);
      },
    ),
  );
}

async function previewGeneratedOutput(
  context: vscode.ExtensionContext,
  uri?: vscode.Uri,
): Promise<void> {
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

  if (!(await ensureDocumentSaved(document, 'Save the file before previewing generated output.'))) {
    return;
  }

  let brickVariables;
  let config;
  try {
    brickVariables = loadBrickVariables(scope.brickYamlPath);
    config = loadBrickGenConfig(scope.configPath);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    void vscode.window.showErrorMessage(`Could not load brick configuration: ${message}`);
    return;
  }

  let variables;
  try {
    variables = resolvePreviewVariables(
      brickVariables,
      document.getText(),
      config,
    );
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    void vscode.window.showErrorMessage(`Could not resolve preview variables: ${message}`);
    return;
  }

  const savedValues = loadSavedPreviewVariables(context, scope.scopeName, variables);
  const selectedValues = await collectPreviewVariableValues(variables, savedValues);
  if (selectedValues === undefined) {
    return;
  }

  await savePreviewVariables(context, scope.scopeName, selectedValues);

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
      title: 'Generating preview…',
      cancellable: false,
    },
    async () => {
      try {
        const previewContent = await runGeneratedPreview({
          scope,
          filePath: document.fileName,
          cli,
          vars: selectedValues,
        });
        await openPreviewDiff(document, previewContent, 'Preview');
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        void vscode.window.showErrorMessage(`Preview failed: ${message}`);
      }
    },
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

  if (!(await ensureDocumentSaved(document, 'Save the file before previewing template output.'))) {
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
        await openPreviewDiff(document, previewContent, 'Template preview');
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

async function ensureDocumentSaved(
  document: vscode.TextDocument,
  cancelMessage: string,
): Promise<boolean> {
  if (!document.isDirty) {
    return true;
  }

  const saved = await document.save();
  if (!saved) {
    void vscode.window.showWarningMessage(cancelMessage);
    return false;
  }

  return true;
}

async function openPreviewDiff(
  original: vscode.TextDocument,
  previewContent: string,
  titlePrefix: string,
): Promise<void> {
  const previewDocument = await vscode.workspace.openTextDocument({
    content: previewContent,
    language: original.languageId,
  });
  const title = `${titlePrefix}: ${path.basename(original.fileName)}`;
  await vscode.commands.executeCommand(
    'vscode.diff',
    original.uri,
    previewDocument.uri,
    title,
  );
}
