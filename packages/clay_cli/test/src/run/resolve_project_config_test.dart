import 'dart:io';

import 'package:clay_cli/src/run/resolve_project_config.dart';
import 'package:clay_core/clay.dart' show clayCoreVersion;
import 'package:clay_core/config.dart';
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

    test('resolves an absolute explicit config path as-is', () {
      final configFile = File(p.join(tempDir.path, 'clay.yaml'))
        ..writeAsStringSync('''
reference: reference
target: target
''');

      final absoluteConfigPath = p.normalize(configFile.absolute.path);
      final discovered = discoverProjectConfig(
        configPath: absoluteConfigPath,
        cwd: tempDir.path,
      );

      expect(discovered.configPath, absoluteConfigPath);
      expect(discovered.projectRoot, p.dirname(absoluteConfigPath));
    });
  });

  group('resolveProjectConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_resolve_config_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('loads config when environment.clay is omitted', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
''');

      final resolved = await resolveProjectConfig(cwd: tempDir.path);

      expect(resolved.config.environment.clay.toString(), 'any');
    });

    test('loads config when environment.clay allows the current version', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
environment:
  clay: ^$clayCoreVersion
''');

      final resolved = await resolveProjectConfig(cwd: tempDir.path);

      expect(resolved.config.environment.clay.toString(), '^$clayCoreVersion');
    });

    test('throws when environment.clay excludes the current version', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
environment:
  clay: ^0.2.0
''');

      await expectLater(
        resolveProjectConfig(cwd: tempDir.path),
        throwsA(
          isA<ClayIncompatibleException>()
              .having(
                (error) => error.currentVersion,
                'currentVersion',
                clayCoreVersion,
              )
              .having(
                (error) => error.requiredConstraint,
                'requiredConstraint',
                '^0.2.0',
              ),
        ),
      );
    });
  });
}
