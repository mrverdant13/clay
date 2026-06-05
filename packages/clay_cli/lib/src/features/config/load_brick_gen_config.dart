import 'dart:convert';
import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/features/config/brick_gen_config_exception.dart';

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
    return BrickGenConfig.fromJson(json);
  } on FormatException catch (error) {
    throw BrickGenConfigException(
      'Invalid brick-gen.json at $configPath: $error',
    );
  } catch (error) {
    throw BrickGenConfigException(
      'Failed to parse brick-gen.json at $configPath: $error',
    );
  }
}
