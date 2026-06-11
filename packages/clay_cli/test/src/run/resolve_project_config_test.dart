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
      final expectedPath = p.normalize(
        p.join(tempDir.path, 'missing-config.yaml'),
      );

      expect(
        () => discoverProjectConfig(
          configPath: 'missing-config.yaml',
          cwd: tempDir.path,
        ),
        throwsA(
          isA<ClayConfigNotFoundException>()
              .having(
                (error) => error.message,
                'message',
                'Config file not found at $expectedPath',
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains('clay.yaml not found')),
              ),
        ),
      );
    });

    test('discovers clay.yaml in the working directory', () {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
''');

      final discovered = discoverProjectConfig(cwd: tempDir.path);

      expect(
        discovered.configPath,
        p.normalize(p.join(tempDir.path, 'clay.yaml')),
      );
    });
  });
}
