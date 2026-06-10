import * as fs from 'node:fs';
import * as path from 'node:path';

/** Relative path to the CLI entrypoint from a Clay workspace root. */
export const CLAY_CLI_SCRIPT_RELATIVE_PATH = path.join(
  'packages',
  'clay_cli',
  'bin',
  'clay.dart',
);

/** Returns the workspace `clay.dart` script from [workspaceRoots], if present. */
export function resolveWorkspaceClayScript(
  workspaceRoots: string[],
): string | undefined {
  for (const root of workspaceRoots) {
    const scriptPath = path.join(root, CLAY_CLI_SCRIPT_RELATIVE_PATH);
    if (fs.existsSync(scriptPath)) {
      return scriptPath;
    }
  }

  return undefined;
}
