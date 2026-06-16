import 'dart:io';

import 'package:clay_core/clay.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:test/test.dart';

void main() {
  group('ClayConfig', () {
    test('can be instantiated with defaults', () {
      final config = ClayConfig();
      expect(config, isA<ClayConfig>());
      expect(config.reference, ClayConfig.defaultReferencePath);
      expect(config.target, ClayConfig.defaultTargetPath);
      expect(config.environment.clay, ClayEnvironment.defaultClayConstraint);
      expect(config.ignore, isEmpty);
      expect(config.replacements, isEmpty);
      expect(config.lineDeletions, isEmpty);
    });

    test('fromMap with explicit path and ignore fields', () {
      final config = ClayConfig.fromMap(const {
        'reference': 'src/reference',
        'target': 'out/template',
        'environment': {'clay': '^0.0.1-dev.1'},
        'ignore': ['.dart_tool/', 'build/'],
        'replacements': [
          {'from': r'^from$', 'to': 'to'},
        ],
        'lineDeletions': [
          {
            'filePath': 'file/path',
            'ranges': [
              {'start': 1, 'end': 5},
            ],
          },
        ],
      });
      expect(
        config,
        isA<ClayConfig>()
            .having((r) => r.reference, 'reference', 'src/reference')
            .having((r) => r.target, 'target', 'out/template')
            .having(
              (r) => r.environment.clay,
              'environment.clay',
              VersionConstraint.parse('^0.0.1-dev.1'),
            )
            .having((r) => r.ignore, 'ignore', ['.dart_tool/', 'build/'])
            .having((r) => r.replacements, 'replacements', isNotEmpty)
            .having((r) => r.lineDeletions, 'lineDeletions', isNotEmpty),
      );
    });

    test('fromMap applies defaults for missing path and ignore fields', () {
      final config = ClayConfig.fromMap(const {
        'replacements': [
          {'from': r'^from$', 'to': 'to'},
        ],
      });
      expect(config.reference, ClayConfig.defaultReferencePath);
      expect(config.target, ClayConfig.defaultTargetPath);
      expect(config.environment.clay, ClayEnvironment.defaultClayConstraint);
      expect(config.ignore, isEmpty);
      expect(config.lineDeletions, isEmpty);
    });

    test('can be compared', () {
      final reference = ClayConfig();
      final same = ClayConfig();
      final other = ClayConfig(
        replacements: [Replacement(from: RegExp(r'^from$'), to: 'to')],
      );

      expect(reference, same);
      expect(reference, isNot(other));
    });

    test('has consistent hash code', () {
      final reference = ClayConfig();
      final same = ClayConfig();
      final other = ClayConfig(
        replacements: [Replacement(from: RegExp(r'^from$'), to: 'to')],
      );

      expect(reference.hashCode, same.hashCode);
      expect(reference.hashCode, isNot(other.hashCode));
    });

    group('clay config fixtures', () {
      final configFixtures = <String, String>{
        'minimal': p.join(_fixturesRoot, 'minimal.yaml'),
        'with_deletions': p.join(_fixturesRoot, 'with_deletions.yaml'),
      };

      for (final entry in configFixtures.entries) {
        test('parses ${entry.key} fixture via fromMap', () async {
          final file = File(entry.value);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Expected fixture at ${entry.value}',
          );

          final config = await loadClayConfig(configPath: file.path);

          expect(config.reference, ClayConfig.defaultReferencePath);
          expect(config.target, ClayConfig.defaultTargetPath);
          expect(
            config.environment.clay,
            ClayEnvironment.defaultClayConstraint,
          );
          expect(config.ignore, isEmpty);
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
  });
}

final String _fixturesRoot = p.normalize(
  p.join(Directory.current.path, 'test', 'fixtures', 'clay'),
);
