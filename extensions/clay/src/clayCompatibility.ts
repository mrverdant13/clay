import semver from 'semver';

import type { ClayConfig } from './clayConfig';

/** Default `environment.clay` when omitted from `clay.yaml`. */
export const DEFAULT_CLAY_CONSTRAINT = 'any';

/** Formats a version mismatch message matching the Clay CLI output. */
export function formatClayIncompatibleMessage(
  currentVersion: string,
  requiredConstraint: string,
): string {
  return (
    `The current clay version is ${currentVersion}.\n` +
    `This project requires clay version ${requiredConstraint}.`
  );
}

/** Validates [constraint] as a semver version constraint. */
export function validateClayVersionConstraint(constraint: string): void {
  if (constraint.length === 0) {
    throw new Error('environment.clay must not be empty');
  }

  if (constraint === DEFAULT_CLAY_CONSTRAINT) {
    return;
  }

  try {
    new semver.Range(constraint, { includePrerelease: true });
  } catch {
    throw new Error(`environment.clay must be a valid semver constraint: ${constraint}`);
  }
}

/** Returns whether [cliVersion] satisfies [config.environment.clay]. */
export function isClayConfigCompatibleWithCliVersion(
  config: ClayConfig,
  cliVersion: string,
): boolean {
  const constraint = config.environment.clay;
  if (constraint === DEFAULT_CLAY_CONSTRAINT) {
    return true;
  }

  return semver.satisfies(cliVersion, constraint, { includePrerelease: true });
}

/** Throws when [config] is not compatible with [cliVersion]. */
export function assertClayConfigCompatibleWithCli(
  config: ClayConfig,
  cliVersion: string,
): void {
  if (isClayConfigCompatibleWithCliVersion(config, cliVersion)) {
    return;
  }

  throw new Error(
    formatClayIncompatibleMessage(cliVersion, config.environment.clay),
  );
}
