import * as fs from 'node:fs';
import * as path from 'node:path';

/** Filename for the brick generation config at the project root. */
export const BRICK_GEN_CONFIG_FILE_NAME = 'brick-gen.json';

/** Default reference directory when omitted from config. */
export const DEFAULT_REFERENCE_PATH = 'reference';

/** Default target directory when omitted from config. */
export const DEFAULT_TARGET_PATH = path.join('brick', '__brick__');

/** Parsed `brick-gen.json` fields used by the extension. */
export interface BrickGenConfig {
  reference: string;
  target: string;
  ignore: string[];
}

interface BrickGenJson {
  reference?: string;
  target?: string;
  ignore?: string[];
}

function readStringField(
  document: BrickGenJson,
  field: 'reference' | 'target',
  defaultValue: string,
): string {
  const value = document[field];
  return typeof value === 'string' ? value : defaultValue;
}

function readIgnoreField(document: BrickGenJson): string[] {
  if (!Array.isArray(document.ignore)) {
    return [];
  }

  return document.ignore.filter((pattern): pattern is string => typeof pattern === 'string');
}

/** Parses `brick-gen.json` contents. */
export function parseBrickGenConfig(raw: string): BrickGenConfig {
  const document = JSON.parse(raw) as BrickGenJson;

  return {
    reference: readStringField(document, 'reference', DEFAULT_REFERENCE_PATH),
    target: readStringField(document, 'target', DEFAULT_TARGET_PATH),
    ignore: readIgnoreField(document),
  };
}

/** Loads and parses `brick-gen.json` from [configPath]. */
export function loadBrickGenConfig(configPath: string): BrickGenConfig {
  const raw = fs.readFileSync(configPath, 'utf8');
  return parseBrickGenConfig(raw);
}

/** Resolves [configPath] relative to [projectRoot], or normalizes it when absolute. */
export function resolvePathFromProjectRoot(projectRoot: string, configPath: string): string {
  if (path.isAbsolute(configPath)) {
    return path.normalize(configPath);
  }
  return path.normalize(path.join(projectRoot, configPath));
}

/** Resolves the reference directory for [config] under [projectRoot]. */
export function resolveReferencePath(projectRoot: string, config: BrickGenConfig): string {
  return resolvePathFromProjectRoot(projectRoot, config.reference);
}

/** Resolves the target directory for [config] under [projectRoot]. */
export function resolveTargetPath(projectRoot: string, config: BrickGenConfig): string {
  return resolvePathFromProjectRoot(projectRoot, config.target);
}
