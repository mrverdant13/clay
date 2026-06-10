import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

import { formatVarsForCli } from './brickVariables';
import type { ClayCliInvocation } from './clayCli';
import type { BrickScopeInfo } from './brickScope';
import type { PreviewVarValue } from './previewVariableState';

const execFileAsync = promisify(execFile);

/** Shared options for preview CLI invocations. */
export interface RunPreviewOptions {
  scope: BrickScopeInfo;
  filePath: string;
  cli: ClayCliInvocation;
}

/** Options for a template-only preview run. */
export type RunTemplatePreviewOptions = RunPreviewOptions;

/** Options for a full generated preview run. */
export interface RunGeneratedPreviewOptions extends RunPreviewOptions {
  vars: Record<string, PreviewVarValue>;
}

/** Runs `clay preview --template-only` and returns stdout content. */
export async function runTemplatePreview(
  options: RunTemplatePreviewOptions,
): Promise<string> {
  return runPreview({
    ...options,
    templateOnly: true,
  });
}

/** Runs `clay preview --vars` and returns stdout content. */
export async function runGeneratedPreview(
  options: RunGeneratedPreviewOptions,
): Promise<string> {
  return runPreview({
    ...options,
    templateOnly: false,
    vars: options.vars,
  });
}

async function runPreview(
  options: RunPreviewOptions & {
    templateOnly: boolean;
    vars?: Record<string, PreviewVarValue>;
  },
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
  ];

  if (options.templateOnly) {
    args.push('--template-only');
  } else {
    const varsArg = formatVarsForCli(options.vars ?? {});
    if (varsArg.length > 0) {
      args.push('--vars', varsArg);
    }
  }

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
