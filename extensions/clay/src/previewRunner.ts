import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

import type { ClayCliInvocation } from './clayCli';
import type { BrickScopeInfo } from './brickScope';

const execFileAsync = promisify(execFile);

/** Options for a template-only preview run. */
export interface RunTemplatePreviewOptions {
  scope: BrickScopeInfo;
  filePath: string;
  cli: ClayCliInvocation;
}

/** Runs `clay preview --template-only` and returns stdout content. */
export async function runTemplatePreview(
  options: RunTemplatePreviewOptions,
): Promise<string> {
  const args = [
    ...options.cli.prefixArgs,
    'preview',
    '--file',
    options.filePath,
    '--config',
    options.scope.configPath,
    '--cwd',
    options.scope.projectRoot,
    '--template-only',
  ];

  try {
    const { stdout } = await execFileAsync(options.cli.executable, args, {
      cwd: options.scope.projectRoot,
      maxBuffer: 16 * 1024 * 1024,
    });
    return stdout;
  } catch (error) {
    throw toPreviewCommandError(error);
  }
}

function toPreviewCommandError(error: unknown): Error {
  if (!(error instanceof Error) || !('stderr' in error)) {
    return error instanceof Error ? error : new Error(String(error));
  }

  const execError = error as Error & { stderr?: string | Buffer; code?: number };
  const stderr =
    typeof execError.stderr === 'string'
      ? execError.stderr
      : (execError.stderr?.toString() ?? '');
  const message = stderr.trim() || execError.message;
  return new Error(message);
}
