import 'dart:io';

import 'package:clay/src/entities/clay_config.dart';
import 'package:clay/src/features/config/clay_config_exception.dart';
import 'package:clay/src/features/config/parse_config_map.dart';
import 'package:clay/src/features/config/yaml_to_dart.dart';
import 'package:yaml/yaml.dart';

/// Loads and parses `clay.yaml` from [configPath].
Future<ClayConfig> loadClayConfig({
  required String configPath,
}) async {
  final file = File(configPath);
  if (!file.existsSync()) {
    throw ClayConfigException(
      'clay.yaml not found at $configPath',
    );
  }

  try {
    final raw = await file.readAsString();
    final parsed = loadYaml(raw);
    if (parsed is! Map) {
      throw ClayConfigException(
        'Invalid clay.yaml at $configPath: expected a YAML mapping',
      );
    }

    final map = Map<String, dynamic>.from(
      yamlToDart(parsed)! as Map,
    );
    return parseConfigMap(map);
  } on YamlException catch (error) {
    throw ClayConfigException(
      'Invalid clay.yaml at $configPath: $error',
    );
  } on FormatException catch (error) {
    if (error.message.startsWith('ignore pattern must')) {
      throw ClayConfigException(
        'Invalid ignore patterns in clay.yaml at $configPath: '
        '${error.message}',
      );
    }
    throw ClayConfigException(
      'Invalid clay.yaml at $configPath: $error',
    );
  } catch (error) {
    if (error is ClayConfigException) {
      rethrow;
    }
    throw ClayConfigException(
      'Failed to parse clay.yaml at $configPath: $error',
    );
  }
}
