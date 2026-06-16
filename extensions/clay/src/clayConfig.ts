import * as fs from 'node:fs';
import * as path from 'node:path';
import { parse as parseYaml } from 'yaml';

import {
  DEFAULT_CLAY_CONSTRAINT,
  validateClayVersionConstraint,
} from './clayCompatibility';

/** Filename for the Clay config at the project root. */
export const CLAY_CONFIG_FILE_NAME = 'clay.yaml';

/** Default reference directory when omitted from config. */
export const DEFAULT_REFERENCE_PATH = 'reference';

/** Default target directory when omitted from config. */
export const DEFAULT_TARGET_PATH = path.join('brick', '__brick__');

/** A content replacement from `clay.yaml`. */
export interface ClayReplacement {
  from: RegExp;
  to: string;
}

/** Semver environment constraints declared in `clay.yaml`. */
export interface ClayEnvironment {
  clay: string;
}

/** Parsed `clay.yaml` fields used by the extension. */
export interface ClayConfig {
  reference: string;
  target: string;
  ignore: string[];
  replacements: ClayReplacement[];
  environment: ClayEnvironment;
}

interface ClayConfigDocument {
  reference?: string;
  target?: string;
  ignore?: string[];
  replacements?: Array<{ from: string | RegExpSource; to: string }>;
  environment?: {
    clay?: unknown;
    [key: string]: unknown;
  };
}

interface RegExpSource {
  pattern: string;
  dotAll?: boolean;
  multiLine?: boolean;
  unicode?: boolean;
  caseSensitive?: boolean;
}

function readStringField(
  document: ClayConfigDocument,
  field: 'reference' | 'target',
  defaultValue: string,
): string {
  const value = document[field];
  return typeof value === 'string' ? value : defaultValue;
}

function readIgnoreField(document: ClayConfigDocument): string[] {
  if (!Array.isArray(document.ignore)) {
    return [];
  }

  return document.ignore.filter((pattern): pattern is string => typeof pattern === 'string');
}

function readEnvironmentField(document: ClayConfigDocument): ClayEnvironment {
  const environment = document.environment;
  if (
    environment === null ||
    environment === undefined ||
    typeof environment !== 'object' ||
    Array.isArray(environment)
  ) {
    return { clay: DEFAULT_CLAY_CONSTRAINT };
  }

  const clay = environment.clay;
  if (clay === undefined) {
    return { clay: DEFAULT_CLAY_CONSTRAINT };
  }

  if (typeof clay !== 'string') {
    throw new Error('environment.clay must be a string');
  }

  validateClayVersionConstraint(clay);
  return { clay };
}

function readReplacementsField(document: ClayConfigDocument): ClayReplacement[] {
  if (!Array.isArray(document.replacements)) {
    return [];
  }

  return document.replacements
    .filter(
      (replacement): replacement is { from: string | RegExpSource; to: string } =>
        replacement !== null &&
        typeof replacement === 'object' &&
        typeof replacement.to === 'string' &&
        (typeof replacement.from === 'string' ||
          (typeof replacement.from === 'object' &&
            replacement.from !== null &&
            typeof replacement.from.pattern === 'string')),
    )
    .map((replacement) => ({
      from: parseReplacementFrom(replacement.from),
      to: replacement.to,
    }));
}

function parseYamlDocument(raw: string): ClayConfigDocument {
  const trimmed = raw.trim();
  if (trimmed.length === 0) {
    return {};
  }

  const parsed = parseYaml(raw);
  if (parsed === null || parsed === undefined) {
    return {};
  }
  if (typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('Clay config must be a YAML mapping.');
  }

  return parsed as ClayConfigDocument;
}

/** Parses `clay.yaml` contents. */
export function parseClayConfig(raw: string): ClayConfig {
  const document = parseYamlDocument(raw);

  return {
    reference: readStringField(document, 'reference', DEFAULT_REFERENCE_PATH),
    target: readStringField(document, 'target', DEFAULT_TARGET_PATH),
    ignore: readIgnoreField(document),
    replacements: readReplacementsField(document),
    environment: readEnvironmentField(document),
  };
}

/** Applies clay.yaml content replacements in config order. */
export function applyClayReplacements(
  content: string,
  replacements: ClayReplacement[],
): string {
  return replacements.reduce(
    (resolved, replacement) => applyReplacement(resolved, replacement),
    content,
  );
}

function applyReplacement(input: string, replacement: ClayReplacement): string {
  const groupNumbers = [...uniqueCaptureGroups(replacement.to)];
  const captureCount = countCapturingGroups(replacement.from);

  for (const group of groupNumbers) {
    if (group < 1 || group > captureCount) {
      throw new Error(
        `Replacement references capture group \${${group}} but the "from" pattern has ${captureCount} capture group(s).`,
      );
    }
  }

  return input.replace(replacement.from, (...matchArgs) => {
    let resolvedTo = replacement.to;
    for (const group of groupNumbers) {
      const value = matchArgs[group] ?? '';
      resolvedTo = resolvedTo.replaceAll(`\${${group}}`, value);
    }
    return resolvedTo;
  });
}

function countCapturingGroups(regex: RegExp): number {
  const match = new RegExp(`${regex.source}|`, regex.flags).exec('');
  return match ? match.length - 1 : 0;
}

function uniqueCaptureGroups(to: string): number[] {
  const seen = new Set<number>();
  const groups: number[] = [];
  for (const match of to.matchAll(/\$\{(\d+)\}/g)) {
    const group = Number.parseInt(match[1] ?? '', 10);
    if (Number.isNaN(group) || seen.has(group)) {
      continue;
    }
    seen.add(group);
    groups.push(group);
  }
  return groups;
}

function parseReplacementFrom(value: string | RegExpSource): RegExp {
  if (typeof value === 'string') {
    return new RegExp(value, 'g');
  }

  const flags = [
    'g',
    value.caseSensitive === false ? 'i' : '',
    value.multiLine ? 'm' : '',
    value.dotAll ? 's' : '',
    value.unicode ? 'u' : '',
  ].join('');

  return new RegExp(value.pattern, flags);
}

/** Loads and parses `clay.yaml` from [configPath]. */
export function loadClayConfig(configPath: string): ClayConfig {
  const raw = fs.readFileSync(configPath, 'utf8');
  return parseClayConfig(raw);
}

/** Resolves [configPath] relative to [projectRoot], or normalizes it when absolute. */
export function resolvePathFromProjectRoot(projectRoot: string, configPath: string): string {
  if (path.isAbsolute(configPath)) {
    return path.normalize(configPath);
  }
  return path.normalize(path.join(projectRoot, configPath));
}

/** Resolves the reference directory for [config] under [projectRoot]. */
export function resolveReferencePath(projectRoot: string, config: ClayConfig): string {
  return resolvePathFromProjectRoot(projectRoot, config.reference);
}

/** Resolves the target directory for [config] under [projectRoot]. */
export function resolveTargetPath(projectRoot: string, config: ClayConfig): string {
  return resolvePathFromProjectRoot(projectRoot, config.target);
}

/** Resolves the Mason `brick.yaml` path adjacent to the configured target directory. */
export function resolveBrickYamlPath(projectRoot: string, config: ClayConfig): string {
  const targetPath = resolvePathFromProjectRoot(projectRoot, config.target);
  return path.join(path.dirname(targetPath), 'brick.yaml');
}
