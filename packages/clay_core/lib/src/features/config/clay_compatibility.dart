import 'package:clay_core/src/entities/clay_config.dart';
import 'package:clay_core/src/features/config/clay_config_exception.dart';
import 'package:clay_core/src/version.dart';
import 'package:pub_semver/pub_semver.dart';

/// Returns whether [config] is compatible with the current Clay library
/// version.
bool isClayConfigCompatibleWithClay(ClayConfig config) {
  final currentClayVersion = Version.parse(clayCoreVersion);
  return config.environment.clay.allows(currentClayVersion);
}

/// Throws [ClayIncompatibleException] when [config] is not compatible with
/// Clay.
void assertClayCompatible(ClayConfig config) {
  if (isClayConfigCompatibleWithClay(config)) {
    return;
  }

  throw ClayIncompatibleException(
    currentVersion: clayCoreVersion,
    requiredConstraint: config.environment.clay.toString(),
  );
}
