import 'dart:convert';
import 'dart:io';

import 'package:clay/clay.dart';
import 'package:clay_cli/src/features/config/brick_gen_config_exception.dart';
import 'package:clay_cli/src/features/config/matches_ignore_pattern.dart';

/// Loads and parses `brick-gen.json` from [configPath].
Future<BrickGenConfig> loadBrickGenConfig({
  required String configPath,
}) async {
  final file = File(configPath);
  if (!file.existsSync()) {
    throw BrickGenConfigException(
      'brick-gen.json not found at $configPath',
    );
  }

  try {
    final raw = await file.readAsString();
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final config = BrickGenConfig.fromJson(json);
    validateIgnorePatterns(config.ignore);
    return config;
  } on FormatException catch (error) {
    if (error.message.startsWith('ignore pattern must')) {
      throw BrickGenConfigException(
        'Invalid ignore patterns in brick-gen.json at $configPath: '
        '${error.message}',
      );
    }
    throw BrickGenConfigException(
      'Invalid brick-gen.json at $configPath: $error',
    );
  } catch (error) {
    throw BrickGenConfigException(
      'Failed to parse brick-gen.json at $configPath: $error',
    );
  }
}
