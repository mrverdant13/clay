// cspell:words LOCALAPPDATA

import { execFile, type ExecFileOptions } from 'node:child_process';
import * as os from 'node:os';
import * as path from 'node:path';
import { promisify } from 'node:util';

import * as vscode from 'vscode';

import {
  CLAY_CLI_SCRIPT_RELATIVE_PATH,
  resolveWorkspaceClayScript,
} from './workspaceClayScript';

const execFileAsync = promisify(execFile);

export { CLAY_CLI_SCRIPT_RELATIVE_PATH, resolveWorkspaceClayScript };

/** How to invoke the Clay CLI. */
export interface ClayCliInvocation {
  /** Executable name or absolute path. */
  executable: string;

  /** Arguments placed before the Clay subcommand (e.g. `dart run …`). */
  prefixArgs: string[];
}

const INSTALL_HINT =
  'Install the CLI with `dart install clay_cli` after release, ' +
  'set `clay.cliPath`, or open a workspace that contains `packages/clay_cli`.';

/** Resolves an available Clay CLI invocation and verifies it runs. */
export async function resolveClayCli(): Promise<ClayCliInvocation> {
  const configured = vscode.workspace
    .getConfiguration('clay')
    .get<string>('cliPath')
    ?.trim();

  for (const candidate of getCliCandidates(configured)) {
    if (await isClayCliAvailable(candidate)) {
      return candidate;
    }
  }

  throw new Error(`The clay CLI was not found.\n${INSTALL_HINT}`);
}

/** Result of a `clay compat` subprocess probe. */
export interface ClayCompatResult {
  exitCode: number;
  stderr: string;
}

/** Options for invoking `clay compat` against a brick scope. */
export interface RunClayCompatOptions {
  configPath: string;
  projectRoot: string;
}

type ClayCliExecFile = (
  executable: string,
  args: string[],
  options: ExecFileOptions,
) => Promise<{ stdout: string; stderr: string }>;

const defaultClayCliExecFile: ClayCliExecFile = async (
  executable,
  args,
  options,
) => execFileAsync(executable, args, options);

let clayCliExecFile: ClayCliExecFile = defaultClayCliExecFile;

/** @internal Overrides subprocess execution for unit tests. */
export function setClayCliExecFileForTests(override?: ClayCliExecFile): void {
  clayCliExecFile = override ?? defaultClayCliExecFile;
}

/** @internal Overrides `clay compat` subprocess execution for unit tests. */
export function setClayCompatExecFileForTests(override?: ClayCliExecFile): void {
  const compatExecFile = override ?? defaultClayCliExecFile;
  setClayCompatExecFileOverride(compatExecFile);
}

let clayCompatExecFile: ClayCliExecFile = defaultClayCliExecFile;

function setClayCompatExecFileOverride(override: ClayCliExecFile): void {
  clayCompatExecFile = override;
}

/** Runs `clay compat` and returns exit code and stderr (no stdout). */
export async function runClayCompat(
  invocation: ClayCliInvocation,
  options: RunClayCompatOptions,
): Promise<ClayCompatResult> {
  const args = [
    ...invocation.prefixArgs,
    'compat',
    '--config',
    options.configPath,
    '--cwd',
    options.projectRoot,
  ];

  try {
    await clayCompatExecFile(invocation.executable, args, {
      cwd: options.projectRoot,
      timeout: 10_000,
    });
    return { exitCode: 0, stderr: '' };
  } catch (error) {
    return {
      exitCode: readExecExitCode(error),
      stderr: readExecStderr(error),
    };
  }
}

function getCliCandidates(configured?: string): ClayCliInvocation[] {
  const candidates: ClayCliInvocation[] = [];

  if (configured) {
    candidates.push({ executable: configured, prefixArgs: [] });
  }

  candidates.push(
    { executable: 'clay', prefixArgs: [] },
    { executable: getDefaultDartInstallExecutable(), prefixArgs: [] },
    { executable: getPubCacheClayExecutable(), prefixArgs: [] },
  );

  const workspaceScript = findWorkspaceClayScript();
  if (workspaceScript) {
    candidates.push({
      executable: 'dart',
      prefixArgs: ['run', workspaceScript],
    });
  }

  return candidates.filter(
    (candidate): candidate is ClayCliInvocation =>
      Boolean(candidate.executable?.trim()),
  );
}

/** Returns the workspace `clay.dart` script when a folder contains it. */
export function findWorkspaceClayScript(): string | undefined {
  const folders = vscode.workspace.workspaceFolders;
  if (!folders) {
    return undefined;
  }

  return resolveWorkspaceClayScript(folders.map((folder) => folder.uri.fsPath));
}

function getPubCacheClayExecutable(): string {
  const configuredCache = process.env.PUB_CACHE?.trim();
  if (process.platform === 'win32') {
    const pubCache =
      configuredCache ??
      (process.env.LOCALAPPDATA?.trim()
        ? path.join(process.env.LOCALAPPDATA.trim(), 'Pub', 'Cache')
        : undefined);
    if (pubCache) {
      return path.join(pubCache, 'bin', 'clay.bat');
    }
    return 'clay.bat';
  }

  const pubCache = configuredCache ?? path.join(os.homedir(), '.pub-cache');
  return path.join(pubCache, 'bin', 'clay');
}

function getDefaultDartInstallExecutable(): string {
  if (process.platform === 'win32') {
    const localAppData = process.env.LOCALAPPDATA?.trim();
    if (localAppData) {
      return path.join(localAppData, 'Dart', 'install', 'bin', 'clay.exe');
    }
    return 'clay.exe';
  }

  if (process.platform === 'darwin') {
    return path.join(
      os.homedir(),
      'Library/Application Support/Dart/install/bin/clay',
    );
  }

  return path.join(os.homedir(), '.local/share/Dart/install/bin/clay');
}

async function isClayCliAvailable(invocation: ClayCliInvocation): Promise<boolean> {
  try {
    await clayCliExecFile(
      invocation.executable,
      [...invocation.prefixArgs, 'compat', '--help'],
      { timeout: 10_000 },
    );
    return true;
  } catch {
    return false;
  }
}

function readExecStderr(error: unknown): string {
  if (typeof error !== 'object' || error === null || !('stderr' in error)) {
    return '';
  }
  const stderr = (error as { stderr?: string | Buffer }).stderr;
  if (typeof stderr === 'string') {
    return stderr;
  }
  return stderr?.toString() ?? '';
}

function readExecExitCode(error: unknown): number {
  if (typeof error !== 'object' || error === null || !('code' in error)) {
    return 1;
  }

  const code = (error as NodeJS.ErrnoException).code;
  if (typeof code === 'number') {
    return code;
  }

  return 1;
}
