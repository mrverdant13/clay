import 'dart:io';

import 'package:clay/clay.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('loadClayConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_load_clay_config_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loads and parses a valid config file', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('''
reference: src/reference
target: out/template
replacements:
  - from: from
    to: to
''');

      final config = await loadClayConfig(configPath: configFile.path);

      expect(config.reference, 'src/reference');
      expect(config.target, 'out/template');
      expect(config.replacements, isNotEmpty);
    });

    test('applies defaults for missing path fields', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('{}');

      final config = await loadClayConfig(configPath: configFile.path);

      expect(config.reference, ClayConfig.defaultReferencePath);
      expect(config.target, ClayConfig.defaultTargetPath);
    });

    test('throws when config file does not exist', () async {
      final missingPath = p.join(tempDir.path, 'missing.yaml');

      expect(
        () => loadClayConfig(configPath: missingPath),
        throwsA(
          isA<ClayConfigException>().having(
            (error) => error.message,
            'message',
            contains('not found'),
          ),
        ),
      );
    });

    test('throws when config file contains invalid YAML', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('reference: [ invalid yaml');

      expect(
        () => loadClayConfig(configPath: configFile.path),
        throwsA(
          isA<ClayConfigException>().having(
            (error) => error.message,
            'message',
            allOf(contains('Invalid'), contains(configFile.path)),
          ),
        ),
      );
    });

    test('throws when config file contains invalid schema', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('replacements: invalid');

      expect(
        () => loadClayConfig(configPath: configFile.path),
        throwsA(
          isA<ClayConfigException>().having(
            (error) => error.message,
            'message',
            allOf(contains('Failed to parse'), contains(configFile.path)),
          ),
        ),
      );
    });

    test('throws when config file is not a YAML mapping', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('- item');

      expect(
        () => loadClayConfig(configPath: configFile.path),
        throwsA(
          isA<ClayConfigException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('expected a YAML mapping'),
              contains(configFile.path),
            ),
          ),
        ),
      );
    });

    test('throws when ignore patterns use backslashes', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString(r'''
ignore:
  - build/
  - packages\app\build
''');

      expect(
        () => loadClayConfig(configPath: configFile.path),
        throwsA(
          isA<ClayConfigException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Invalid ignore patterns'),
              contains('POSIX-style forward slashes'),
              contains(configFile.path),
            ),
          ),
        ),
      );
    });

    test('throws when ignore patterns use Windows-absolute paths', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('''
ignore:
  - build/
  - C:/Users/app/build
''');

      expect(
        () => loadClayConfig(configPath: configFile.path),
        throwsA(
          isA<ClayConfigException>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Invalid ignore patterns'),
              contains('Windows-absolute paths'),
              contains(configFile.path),
            ),
          ),
        ),
      );
    });

    test('accepts root-anchored ignore patterns', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('''
ignore:
  - /build/
  - packages/app/.dart_tool/
''');

      final config = await loadClayConfig(configPath: configFile.path);

      expect(config.ignore, ['/build/', 'packages/app/.dart_tool/']);
    });

    test('accepts POSIX-looking root-anchored ignore patterns', () async {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'));
      await configFile.writeAsString('''
ignore:
  - /Users/app/build/
  - /home/user/.cache/
''');

      final config = await loadClayConfig(configPath: configFile.path);

      expect(config.ignore, ['/Users/app/build/', '/home/user/.cache/']);
    });
  });

  group('clay config fixtures', () {
    final configFixtures = <String, String>{
      'minimal': p.join(_fixturesRoot, 'minimal.yaml'),
      'with_deletions': p.join(_fixturesRoot, 'with_deletions.yaml'),
      'full': p.join(_fixturesRoot, 'full.yaml'),
    };

    for (final entry in configFixtures.entries) {
      test('parses ${entry.key} fixture', () async {
        final file = File(entry.value);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Expected fixture at ${entry.value}',
        );

        final config = await loadClayConfig(configPath: file.path);

        if (entry.key == 'full') {
          expect(config.reference, 'src/reference');
          expect(config.target, 'out/template');
          expect(config.ignore, hasLength(5));
        } else {
          expect(config.reference, ClayConfig.defaultReferencePath);
          expect(config.target, ClayConfig.defaultTargetPath);
          expect(config.ignore, isEmpty);
        }
        expect(config.replacements, isNotEmpty);

        if (entry.key == 'with_deletions') {
          expect(config.lineDeletions, isNotEmpty);
          expect(
            config.lineDeletions.first,
            isA<LineDeletion>()
                .having((r) => r.filePath, 'filePath', isNotEmpty)
                .having((r) => r.ranges, 'ranges', isNotEmpty),
          );
        }
      });
    }

    test('parses dotAll replacement object from with_deletions', () async {
      final file = File(configFixtures['with_deletions']!);
      final config = await loadClayConfig(configPath: file.path);

      final dotAllReplacement = config.replacements.firstWhere(
        (replacement) => replacement.from.isDotAll,
      );
      expect(dotAllReplacement.from.pattern, r'@Dependencies\(\[(.*?)\]\)');
      expect(
        dotAllReplacement.to,
        r'{{#use_riverpod}}@Dependencies([${1}]){{/use_riverpod}}',
      );
    });

    test('parses line deletion ranges from with_deletions', () async {
      final file = File(configFixtures['with_deletions']!);
      final config = await loadClayConfig(configPath: file.path);

      expect(
        config.lineDeletions.first.ranges.first,
        const LineRange(start: 51, end: 158),
      );
    });
  });
}

final String _fixturesRoot = p.normalize(
  p.join(Directory.current.path, 'test', 'fixtures', 'clay'),
);
