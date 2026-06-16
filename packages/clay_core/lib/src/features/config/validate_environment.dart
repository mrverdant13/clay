import 'package:clay_core/src/entities/clay_config.dart';
import 'package:clay_core/src/entities/clay_environment.dart';

/// Allowed keys inside the `environment` block of `clay.yaml`.
const _allowedEnvironmentKeys = {'clay'};

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
  if (environment.clay.isEmpty) {
    throw const FormatException('environment.clay must not be empty');
  }
}
