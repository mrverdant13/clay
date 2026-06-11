import 'dart:io';

import 'package:clay/config.dart';
import 'package:clay_cli/src/run/resolve_project_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('discoverProjectConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_resolve_config_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('uses a neutral not-found message for explicit config paths', () {
      expect(
        () => discoverProjectConfig(
          configPath: 'missing-config.json',
          cwd: tempDir.path,
        ),
        throwsA(
          isA<ClayConfigNotFoundException>()
              .having(
                (error) => error.message,
                'message',
                'Config file not found at ${p.normalize(p.join(tempDir.path, 'missing-config.json'))}',
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains('clay.yaml not found')),
              ),
        ),
      );
    });

    test('discovers clay.yaml before brick-gen.json when both exist', () {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
''');
      File(p.join(tempDir.path, 'brick-gen.json')).writeAsStringSync('{}');

      final discovered = discoverProjectConfig(cwd: tempDir.path);

      expect(
        discovered.configPath,
        p.normalize(p.join(tempDir.path, 'clay.yaml')),
      );
    });
  });
}
