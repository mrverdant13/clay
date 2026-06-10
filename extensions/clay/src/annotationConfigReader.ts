import * as vscode from 'vscode';

import { type AnnotationConfig, resolveAnnotationConfig } from './annotationConfig';

/** Reads the current workspace `clay.colors.*` configuration. */
export function readAnnotationConfig(): AnnotationConfig {
  const configuration = vscode.workspace.getConfiguration('clay');
  return resolveAnnotationConfig((key, defaultValue) =>
    configuration.get<string>(key, defaultValue),
  );
}
