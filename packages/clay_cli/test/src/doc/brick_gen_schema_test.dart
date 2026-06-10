import 'dart:convert';
import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('brick-gen.schema.json', () {
    late Map<String, dynamic> schema;

    setUp(() {
      final schemaFile = File(_schemaPath);
      expect(
        schemaFile.existsSync(),
        isTrue,
        reason: 'Expected schema at $_schemaPath',
      );
      schema =
          jsonDecode(schemaFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('is valid JSON with expected top-level shape', () {
      expect(schema[r'$schema'], isNotNull);
      expect(schema['title'], 'Clay brick-gen.json');
      expect(schema['type'], 'object');
      expect(schema['additionalProperties'], isFalse);

      final properties = schema['properties'] as Map<String, dynamic>;
      expect(
        properties.keys,
        containsAll([
          'reference',
          'target',
          'ignore',
          'replacements',
          'lineDeletions',
        ]),
      );
    });

    test('declares replacement from as string or regex object', () {
      final defs = schema[r'$defs'] as Map<String, dynamic>;
      final replacement = defs['replacement'] as Map<String, dynamic>;
      final replacementProperties =
          replacement['properties'] as Map<String, dynamic>;
      final from = replacementProperties['from'] as Map<String, dynamic>;
      final oneOf = from['oneOf'] as List<dynamic>;

      expect(oneOf, hasLength(2));
      expect((oneOf.first as Map<String, dynamic>)['type'], 'string');
      expect(
        (oneOf.last as Map<String, dynamic>)[r'$ref'],
        r'#/$defs/regexPattern',
      );
    });

    group('example configs validate against entity parsing', () {
      final examples = [
        {
          'reference': 'reference',
          'target': 'brick/__brick__',
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
        },
        {
          'replacements': [
            {
              'from': {
                'pattern': r'@Dependencies\(\[(.*?)\]\)',
                'dotAll': true,
              },
              'to': r'{{#use_riverpod}}@Dependencies([${1}]){{/use_riverpod}}',
            },
          ],
        },
      ];

      for (final (index, example) in examples.indexed) {
        test('schema example $index parses via BrickGenConfig.fromJson', () {
          expect(() => BrickGenConfig.fromJson(example), returnsNormally);
        });
      }
    });

    group('fixture configs', () {
      final fixturesRoot = p.normalize(
        p.join(Directory.current.path, 'test', 'fixtures', 'brick_gen'),
      );

      for (final entry
          in Directory(fixturesRoot).listSync().whereType<File>()) {
        if (!entry.path.endsWith('.json')) {
          continue;
        }

        test(
          '${p.basename(entry.path)} parses via BrickGenConfig.fromJson',
          () {
            final json =
                jsonDecode(entry.readAsStringSync()) as Map<String, dynamic>;
            expect(() => BrickGenConfig.fromJson(json), returnsNormally);
          },
        );
      }
    });
  });
}

final String _schemaPath = p.normalize(
  p.join(
    Directory.current.path,
    '..',
    '..',
    'doc',
    'brick-gen.schema.json',
  ),
);
