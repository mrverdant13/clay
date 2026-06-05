import 'dart:convert';
import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/entities/line_deletion.dart';
import 'package:clay_cli/src/entities/line_range.dart';
import 'package:clay_cli/src/entities/replacement.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('BrickGenConfig', () {
    test('can be instantiated with defaults', () {
      const config = BrickGenConfig();
      expect(config, isA<BrickGenConfig>());
      expect(config.reference, defaultReferencePath);
      expect(config.target, defaultTargetPath);
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
      expect(config.reference, defaultReferencePath);
      expect(config.target, defaultTargetPath);
      expect(config.ignore, isEmpty);
      expect(config.lineDeletions, isEmpty);
    });

    test('can be compared', () {
      const reference = BrickGenConfig();
      const same = BrickGenConfig();
      final other = BrickGenConfig(
        replacements: [Replacement(from: RegExp(r'^from$'), to: 'to')],
      );

      expect(reference, same);
      expect(reference, isNot(other));
    });

    test('has consistent hash code', () {
      const reference = BrickGenConfig();
      const same = BrickGenConfig();
      final other = BrickGenConfig(
        replacements: [Replacement(from: RegExp(r'^from$'), to: 'to')],
      );

      expect(reference.hashCode, same.hashCode);
      expect(reference.hashCode, isNot(other.hashCode));
    });

    group('legacy altoke_bricks configs', () {
      final legacyConfigs = <String, String>{
        'altoke_common': p.join(
          _altokeBricksRoot,
          'bricks',
          'altoke_common',
          'brick-gen.json',
        ),
        'altoke_app': p.join(
          _altokeBricksRoot,
          'bricks',
          'altoke_app',
          'brick-gen.json',
        ),
      };

      for (final entry in legacyConfigs.entries) {
        test('parses ${entry.key} brick-gen.json', () {
          final file = File(entry.value);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Expected legacy fixture at ${entry.value}',
          );

          final json =
              jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
          final config = BrickGenConfig.fromJson(json);

          expect(config.reference, defaultReferencePath);
          expect(config.target, defaultTargetPath);
          expect(config.ignore, isEmpty);
          expect(config.replacements, isNotEmpty);

          if (entry.key == 'altoke_app') {
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

      test('parses altoke_app dotAll replacement object', () {
        final file = File(legacyConfigs['altoke_app']!);
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

      test('parses altoke_app line deletion ranges', () {
        final file = File(legacyConfigs['altoke_app']!);
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

/// Sibling checkout used as a local parity fixture source.
final String _altokeBricksRoot = p.normalize(
  p.join(Directory.current.path, '..', '..', '..', 'altoke_bricks'),
);
