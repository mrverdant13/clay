import * as fs from 'node:fs';
import * as path from 'node:path';

import {
  BRICK_GEN_CONFIG_FILE_NAME,
  loadBrickGenConfig,
  resolveReferencePath,
  resolveTargetPath,
} from './brickGen';

/** Resolved brick scope for a reference file. */
export interface BrickScopeInfo {
  /** Directory containing `brick-gen.json`. */
  projectRoot: string;

  /** Absolute path to `brick-gen.json`. */
  configPath: string;

  /** Resolved reference project root. */
  referenceDir: string;

  /** Resolved template output root. */
  targetDir: string;
}

/** Collects candidate `brick-gen.json` paths when walking up from [startDir]. */
export function collectConfigSearchPaths(startDir: string): string[] {
  const normalized = path.normalize(path.resolve(startDir));
  const candidates: string[] = [];
  let current = normalized;

  while (true) {
    candidates.push(path.join(current, BRICK_GEN_CONFIG_FILE_NAME));
    const parent = path.dirname(current);
    if (parent === current) {
      break;
    }
    current = parent;
  }

  return candidates;
}

/** Returns whether [targetPath] is inside [directoryPath] (not equal to it). */
export function isPathWithinDirectory(targetPath: string, directoryPath: string): boolean {
  const relative = path.relative(directoryPath, targetPath);
  if (relative === '' || path.isAbsolute(relative)) {
    return false;
  }
  return relative !== '..' && !relative.startsWith(`..${path.sep}`);
}

/**
 * Finds the brick scope for [filePath] by walking up to the nearest
 * `brick-gen.json` and verifying the file lies under the configured reference
 * root.
 */
export function findBrickScopeForFile(filePath: string): BrickScopeInfo | undefined {
  const resolvedFile = path.resolve(filePath);
  const searchPaths = collectConfigSearchPaths(path.dirname(resolvedFile));

  for (const configPath of searchPaths) {
    if (!fs.existsSync(configPath)) {
      continue;
    }

    try {
      const projectRoot = path.dirname(configPath);
      const config = loadBrickGenConfig(configPath);
      const referenceDir = resolveReferencePath(projectRoot, config);

      if (!isPathWithinDirectory(resolvedFile, referenceDir)) {
        continue;
      }

      return {
        projectRoot,
        configPath,
        referenceDir,
        targetDir: resolveTargetPath(projectRoot, config),
      };
    } catch {
      continue;
    }
  }

  return undefined;
}
