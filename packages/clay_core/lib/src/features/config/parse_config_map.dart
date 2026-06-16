import 'package:clay_core/src/entities/clay_config.dart';
import 'package:clay_core/src/features/config/matches_ignore_pattern.dart';
import 'package:clay_core/src/features/config/validate_environment.dart';

/// Parses a config map into a [ClayConfig] and validates ignore patterns.
ClayConfig parseConfigMap(Map<String, dynamic> map) {
  validateEnvironmentMap(map);
  final config = ClayConfig.fromMap(map);
  validateClayEnvironment(config.environment);
  validateIgnorePatterns(config.ignore);
  return config;
}
