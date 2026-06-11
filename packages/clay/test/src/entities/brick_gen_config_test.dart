import 'dart:convert';
import 'dart:io';

import 'package:clay/clay.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('BrickGenConfig', () {
    test('can be instantiated with defaults', () {
      final config = BrickGenConfig();
      expect(config, isA<BrickGenConfig>());
      expect(config.reference, BrickGenConfig.defaultReferencePath);
      expect(config.target, BrickGenConfig.defaultTargetPath);
      expect(config.ignore, isEmpty);
      expect(config.replacements, isEmpty);
      expect(config.lineDeletions, isEmpty);
    });

    test('fromJson with explicit path and ignore fields', () {
      final config = BrickGenConfig.fromJson(const {
        'reference': 'src/reference',
        'target': 'out/template',
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
        isA<BrickGenConfig>()
            .having((r) => r.reference, 'reference', 'src/reference')
            .having((r) => r.target, 'target', 'out/template')
            .having((r) => r.ignore, 'ignore', ['.dart_tool/', 'build/'])
            .having((r) => r.replacements, 'replacements', isNotEmpty)
            .having((r) => r.lineDeletions, 'lineDeletions', isNotEmpty),
      );
    });

    test('fromJson applies defaults for missing path and ignore fields', () {
      final config = BrickGenConfig.fromJson(const {
        'replacements': [
          {'from': r'^from$', 'to': 'to'},
        ],
      });
      expect(config.reference, BrickGenConfig.defaultReferencePath);
      expect(config.target, BrickGenConfig.defaultTargetPath);
      expect(config.ignore, isEmpty);
      expect(config.lineDeletions, isEmpty);
    });

    test('can be compared', () {
      final reference = BrickGenConfig();
      final same = BrickGenConfig();
      final other = BrickGenConfig(
        replacements: [Replacement(from: RegExp(r'^from$'), to: 'to')],
      );

      expect(reference, same);
      expect(reference, isNot(other));
    });

    test('has consistent hash code', () {
      final reference = BrickGenConfig();
      final same = BrickGenConfig();
      final other = BrickGenConfig(
        replacements: [Replacement(from: RegExp(r'^from$'), to: 'to')],
      );

      expect(reference.hashCode, same.hashCode);
      expect(reference.hashCode, isNot(other.hashCode));
    });

    group('minimal config fixtures', () {
      final configFixtures = <String, String>{
        'minimal': p.join(
          _fixturesRoot,
          'minimal.json',
        ),
        'with_deletions': p.join(
          _fixturesRoot,
          'with_deletions.json',
        ),
      };

      for (final entry in configFixtures.entries) {
        test('parses ${entry.key} fixture', () {
          final file = File(entry.value);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Expected fixture at ${entry.value}',
          );

          final json =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          final config = BrickGenConfig.fromJson(json);

          expect(config.reference, BrickGenConfig.defaultReferencePath);
          expect(config.target, BrickGenConfig.defaultTargetPath);
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

      test('parses dotAll replacement object from with_deletions', () {
        final file = File(configFixtures['with_deletions']!);
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final config = BrickGenConfig.fromJson(json);

        final dotAllReplacement = config.replacements.firstWhere(
          (replacement) => replacement.from.isDotAll,
        );
        expect(dotAllReplacement.from.pattern, r'@Dependencies\(\[(.*?)\]\)');
        expect(
          dotAllReplacement.to,
          r'{{#use_riverpod}}@Dependencies([${1}]){{/use_riverpod}}',
        );
      });

      test('parses line deletion ranges from with_deletions', () {
        final file = File(configFixtures['with_deletions']!);
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final config = BrickGenConfig.fromJson(json);

        expect(
          config.lineDeletions.first.ranges.first,
          const LineRange(start: 51, end: 158),
        );
      });
    });
  });
}

final String _fixturesRoot = p.normalize(
  p.join(Directory.current.path, 'test', 'fixtures', 'brick_gen'),
);
