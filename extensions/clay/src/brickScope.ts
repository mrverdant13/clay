import * as fs from 'node:fs';
import * as path from 'node:path';

import {
  CLAY_CONFIG_FILE_NAME,
  loadClayConfig,
  resolveBrickYamlPath,
  resolveReferencePath,
  resolveTargetPath,
} from './clayConfig';

/** Resolved brick scope for a reference file. */
export interface BrickScopeInfo {
  /** Directory containing `clay.yaml`. */
  projectRoot: string;

  /** Stable scope key for persisted preview variable state. */
  scopeName: string;

  /** Absolute path to `clay.yaml`. */
  configPath: string;

  /** Resolved reference project root. */
  referenceDir: string;

  /** Resolved template output root. */
  targetDir: string;

  /** Resolved Mason `brick.yaml` path adjacent to the target directory. */
  brickYamlPath: string;
}

/** Collects candidate `clay.yaml` paths when walking up from [startDir]. */
export function collectConfigSearchPaths(startDir: string): string[] {
  const normalized = path.normalize(path.resolve(startDir));
  const candidates: string[] = [];
  let current = normalized;

  while (true) {
    candidates.push(path.join(current, CLAY_CONFIG_FILE_NAME));
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
 * `clay.yaml` and verifying the file lies under the configured reference
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
      const config = loadClayConfig(configPath);
      const referenceDir = resolveReferencePath(projectRoot, config);

      if (!isPathWithinDirectory(resolvedFile, referenceDir)) {
        continue;
      }

      return {
        projectRoot,
        scopeName: path.normalize(configPath),
        configPath,
        referenceDir,
        targetDir: resolveTargetPath(projectRoot, config),
        brickYamlPath: resolveBrickYamlPath(projectRoot, config),
      };
    } catch {
      continue;
    }
  }

  return undefined;
}
