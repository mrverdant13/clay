import * as path from 'path';
import * as vscode from 'vscode';

/** Extensions used by Clay reference projects. */
const SUPPORTED_EXTENSIONS = new Set([
  '.dart',
  '.sh',
  '.yaml',
  '.yml',
  '.html',
  '.htm',
  '.xml',
  '.md',
  '.markdown',
]);

/** Ignore-style files that use `#` annotation comments without an extension. */
const SUPPORTED_BASENAMES = new Set(['.gitignore', '.dockerignore']);

/** Document selector for supported reference files (folding, etc.). */
export const SUPPORTED_REFERENCE_FILE_SELECTOR: vscode.DocumentSelector = [
  { scheme: 'file', language: 'dart' },
  { scheme: 'file', language: 'shellscript' },
  { scheme: 'file', language: 'yaml' },
  { scheme: 'file', language: 'html' },
  { scheme: 'file', language: 'xml' },
  { scheme: 'file', language: 'markdown' },
  { scheme: 'file', pattern: '**/.gitignore' },
  { scheme: 'file', pattern: '**/.dockerignore' },
];

export function isSupportedReferenceFile(document: vscode.TextDocument): boolean {
  const basename = path.basename(document.fileName).toLowerCase();
  if (SUPPORTED_BASENAMES.has(basename)) {
    return true;
  }

  return SUPPORTED_EXTENSIONS.has(
    path.extname(document.fileName).toLowerCase(),
  );
}
