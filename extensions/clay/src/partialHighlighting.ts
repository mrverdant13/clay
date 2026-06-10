import * as vscode from 'vscode';

import { findNamedPairedBlockInteriors } from './annotationBlockPairing';
import {
  PARTIAL_BOUNDARY_MARKER_PATTERN,
  PARTIAL_MARKER_SETS,
} from './annotationMarkerSets';
import { type AnnotationConfig } from './annotationConfig';
import {
  clearEditorDecorations,
  interiorsToRanges,
  patternToRanges,
} from './rangeUtils';
import { isSupportedReferenceFile } from './supportedFiles';

let markerDecoration = vscode.window.createTextEditorDecorationType({});
let payloadDecoration = vscode.window.createTextEditorDecorationType({});
let appliedConfigKey = '';

function ensureDecorations(config: AnnotationConfig): void {
  const key = JSON.stringify(config.partial);
  if (key === appliedConfigKey) return;

  const prevMarker = markerDecoration;
  const prevPayload = payloadDecoration;

  markerDecoration = vscode.window.createTextEditorDecorationType({
    color: config.partial.markerForeground,
    fontWeight: 'bold',
  });
  payloadDecoration = vscode.window.createTextEditorDecorationType({
    backgroundColor: config.partial.payloadBackground,
    isWholeLine: false,
  });

  prevMarker.dispose();
  prevPayload.dispose();
  appliedConfigKey = key;
}

export function refreshPartialHighlights(
  editor: vscode.TextEditor | undefined,
  config: AnnotationConfig,
): void {
  ensureDecorations(config);

  if (editor === undefined) return;

  if (!isSupportedReferenceFile(editor.document)) {
    clearEditorDecorations(editor, [markerDecoration, payloadDecoration]);
    return;
  }

  const text = editor.document.getText();

  editor.setDecorations(
    markerDecoration,
    patternToRanges(editor.document, text, PARTIAL_BOUNDARY_MARKER_PATTERN),
  );
  editor.setDecorations(
    payloadDecoration,
    interiorsToRanges(
      editor.document,
      findNamedPairedBlockInteriors(text, PARTIAL_MARKER_SETS),
    ),
  );
}

export function registerPartialHighlighting(context: vscode.ExtensionContext): void {
  context.subscriptions.push(
    new vscode.Disposable(() => {
      markerDecoration.dispose();
      payloadDecoration.dispose();
    }),
  );
}
