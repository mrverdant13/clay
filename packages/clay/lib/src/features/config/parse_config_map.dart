import 'package:clay/src/entities/brick_gen_config.dart';
import 'package:clay/src/entities/clay_config.dart';
import 'package:clay/src/features/config/matches_ignore_pattern.dart';

/// Parses a config map into a [ClayConfig] and validates ignore patterns.
ClayConfig parseConfigMap(Map<String, dynamic> map) {
  final config = BrickGenConfig.fromJson(map);
  validateIgnorePatterns(config.ignore);
  return config;
}
