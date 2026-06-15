import 'dart:io';

import 'package:clay_core/clay.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('discoverClayConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'clay_discover_clay_config_',
      );
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('discovers config in cwd', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      final configFile = File(p.join(projectRoot.path, 'clay.yaml'))
        ..writeAsStringSync('{}');

      final discovered = discoverClayConfig(cwd: projectRoot.path);

      expect(discovered.configPath, configFile.path);
      expect(discovered.projectRoot, projectRoot.path);
    });

    test('walks up parent directories to find config', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      File(p.join(projectRoot.path, 'clay.yaml')).writeAsStringSync('{}');
      final nestedDir = Directory(p.join(projectRoot.path, 'src', 'lib'))
        ..createSync(recursive: true);

      final discovered = discoverClayConfig(cwd: nestedDir.path);

      expect(
        discovered.configPath,
        p.join(projectRoot.path, 'clay.yaml'),
      );
      expect(discovered.projectRoot, projectRoot.path);
    });

    test('uses explicit config path relative to cwd', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      final configDir = Directory(p.join(projectRoot.path, 'config'))
        ..createSync();
      final configFile = File(p.join(configDir.path, 'clay.yaml'))
        ..writeAsStringSync('{}');

      final discovered = discoverClayConfig(
        cwd: projectRoot.path,
        configPath: p.join('config', 'clay.yaml'),
      );

      expect(discovered.configPath, configFile.path);
      expect(discovered.projectRoot, configDir.path);
    });

    test('uses explicit absolute config path', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      final configFile = File(p.join(projectRoot.path, 'clay.yaml'))
        ..writeAsStringSync('{}');

      final discovered = discoverClayConfig(
        configPath: configFile.path,
      );

      expect(discovered.configPath, configFile.path);
      expect(discovered.projectRoot, projectRoot.path);
    });

    test('throws when config cannot be found during walk-up', () {
      final emptyDir = Directory(p.join(tempDir.path, 'empty'))..createSync();

      expect(
        () => discoverClayConfig(cwd: emptyDir.path),
        throwsA(
          isA<ClayConfigNotFoundException>()
              .having(
                (error) => error.message,
                'message',
                contains('not found'),
              )
              .having(
                (error) => error.searchedPaths,
                'searchedPaths',
                isNotEmpty,
              )
              .having(
                (error) => error.toString(),
                'toString',
                contains('Searched paths:'),
              ),
        ),
      );
    });

    test('throws when explicit config path does not exist', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();

      expect(
        () => discoverClayConfig(
          cwd: projectRoot.path,
          configPath: 'missing/clay.yaml',
        ),
        throwsA(isA<ClayConfigNotFoundException>()),
      );
    });
  });

  group('collectClayConfigSearchPaths', () {
    test('returns candidates from start dir up to filesystem root', () {
      final startDir = p.join(Directory.systemTemp.path, 'a', 'b', 'c');
      final candidates = collectClayConfigSearchPaths(startDir: startDir);

      expect(candidates.first, p.join(startDir, 'clay.yaml'));
      expect(
        candidates,
        contains(p.join(Directory.systemTemp.path, 'clay.yaml')),
      );

      final lastCandidate = candidates.last;
      final lastParent = p.dirname(p.dirname(lastCandidate));
      expect(lastParent, p.dirname(lastCandidate));
    });
  });
}
