import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/features/config/brick_gen_config_exception.dart';
import 'package:clay_cli/src/features/config/load_brick_gen_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('loadBrickGenConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_load_config_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loads and parses a valid config file', () async {
      final configFile = File(p.join(tempDir.path, 'brick-gen.json'));
      await configFile.writeAsString('''
{
  "reference": "src/reference",
  "target": "out/template",
  "replacements": [
    {"from": "from", "to": "to"}
  ]
}
''');

      final config = await loadBrickGenConfig(configPath: configFile.path);

      expect(config.reference, 'src/reference');
      expect(config.target, 'out/template');
      expect(config.replacements, isNotEmpty);
    });

    test('applies defaults for missing path fields', () async {
      final configFile = File(p.join(tempDir.path, 'brick-gen.json'));
      await configFile.writeAsString('{}');

      final config = await loadBrickGenConfig(configPath: configFile.path);

      expect(config.reference, BrickGenConfig.defaultReferencePath);
      expect(config.target, BrickGenConfig.defaultTargetPath);
    });

    test('throws when config file does not exist', () async {
      final missingPath = p.join(tempDir.path, 'missing.json');

      expect(
        () => loadBrickGenConfig(configPath: missingPath),
        throwsA(
          isA<BrickGenConfigException>().having(
            (error) => error.message,
            'message',
            contains('not found'),
          ),
        ),
      );
    });

    test('throws when config file contains invalid JSON', () async {
      final configFile = File(p.join(tempDir.path, 'brick-gen.json'));
      await configFile.writeAsString('{ invalid json');

      expect(
        () => loadBrickGenConfig(configPath: configFile.path),
        throwsA(
          isA<BrickGenConfigException>().having(
            (error) => error.message,
            'message',
            allOf(contains('Invalid'), contains(configFile.path)),
          ),
        ),
      );
    });

    test('throws when config file contains invalid schema', () async {
      final configFile = File(p.join(tempDir.path, 'brick-gen.json'));
      await configFile.writeAsString('{"replacements": "invalid"}');

      expect(
        () => loadBrickGenConfig(configPath: configFile.path),
        throwsA(
          isA<BrickGenConfigException>().having(
            (error) => error.message,
            'message',
            allOf(contains('Failed to parse'), contains(configFile.path)),
          ),
        ),
      );
    });

    test('throws when config file is not a JSON object', () async {
      final configFile = File(p.join(tempDir.path, 'brick-gen.json'));
      await configFile.writeAsString('[]');

      expect(
        () => loadBrickGenConfig(configPath: configFile.path),
        throwsA(
          isA<BrickGenConfigException>().having(
            (error) => error.message,
            'message',
            allOf(contains('Failed to parse'), contains(configFile.path)),
          ),
        ),
      );
    });
  });
}
