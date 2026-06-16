import 'package:clay_core/src/entities/clay_environment.dart';
import 'package:pub_semver/pub_semver.dart';

/// Allowed keys inside the `environment` block of `clay.yaml`.
const _allowedEnvironmentKeys = {'clay'};

/// Parses [constraint] as a semver version constraint.
///
/// Throws [FormatException] when [constraint] is not a valid constraint string.
VersionConstraint parseClayVersionConstraint(String constraint) {
  if (constraint.isEmpty) {
    throw const FormatException('environment.clay must not be empty');
  }

  try {
    return VersionConstraint.parse(constraint);
  } on FormatException catch (error) {
    throw FormatException(
      'environment.clay must be a valid semver constraint: ${error.message}',
    );
  }
}

/// Validates the raw `environment` entry before [ClayConfig] mapping.
void validateEnvironmentMap(Map<String, dynamic> map) {
  final environment = map['environment'];
  if (environment == null) {
    return;
  }
  if (environment is! Map) {
    throw const FormatException('environment must be a mapping');
  }

  final environmentMap = Map<Object?, Object?>.from(environment);
  final unknownKeys = environmentMap.keys
      .whereType<String>()
      .where((key) => !_allowedEnvironmentKeys.contains(key))
      .toList();
  if (unknownKeys.isNotEmpty) {
    throw FormatException(
      'environment contains unknown keys: ${unknownKeys.join(', ')}',
    );
  }

  final clay = environmentMap['clay'];
  if (clay != null && clay is! String) {
    throw const FormatException('environment.clay must be a string');
  }
}

/// Validates a parsed [ClayEnvironment].
void validateClayEnvironment(ClayEnvironment environment) {
  parseClayVersionConstraint(environment.clay);
}
