import 'package:clay_core/src/entities/clay_config.dart';
import 'package:clay_core/src/features/config/matches_ignore_pattern.dart';

/// Parses a config map into a [ClayConfig] and validates ignore patterns.
ClayConfig parseConfigMap(Map<String, dynamic> map) {
  final config = ClayConfig.fromMap(map);
  validateIgnorePatterns(config.ignore);
  return config;
}
