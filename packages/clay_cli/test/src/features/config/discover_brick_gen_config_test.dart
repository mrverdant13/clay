import 'dart:io';

import 'package:clay_cli/src/features/config/brick_gen_config_exception.dart';
import 'package:clay_cli/src/features/config/discover_brick_gen_config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('discoverBrickGenConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_discover_config_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('discovers config in cwd', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      final configFile = File(p.join(projectRoot.path, 'brick-gen.json'))
        ..writeAsStringSync('{}');

      final discovered = discoverBrickGenConfig(cwd: projectRoot.path);

      expect(discovered.configPath, configFile.path);
      expect(discovered.projectRoot, projectRoot.path);
    });

    test('walks up parent directories to find config', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      File(p.join(projectRoot.path, 'brick-gen.json')).writeAsStringSync('{}');
      final nestedDir = Directory(p.join(projectRoot.path, 'src', 'lib'))
        ..createSync(recursive: true);

      final discovered = discoverBrickGenConfig(cwd: nestedDir.path);

      expect(
        discovered.configPath,
        p.join(projectRoot.path, 'brick-gen.json'),
      );
      expect(discovered.projectRoot, projectRoot.path);
    });

    test('uses explicit config path relative to cwd', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      final configDir = Directory(p.join(projectRoot.path, 'config'))
        ..createSync();
      final configFile = File(p.join(configDir.path, 'brick-gen.json'))
        ..writeAsStringSync('{}');

      final discovered = discoverBrickGenConfig(
        cwd: projectRoot.path,
        configPath: p.join('config', 'brick-gen.json'),
      );

      expect(discovered.configPath, configFile.path);
      expect(discovered.projectRoot, configDir.path);
    });

    test('uses explicit absolute config path', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();
      final configFile = File(p.join(projectRoot.path, 'brick-gen.json'))
        ..writeAsStringSync('{}');

      final discovered = discoverBrickGenConfig(
        configPath: configFile.path,
      );

      expect(discovered.configPath, configFile.path);
      expect(discovered.projectRoot, projectRoot.path);
    });

    test('throws when config cannot be found during walk-up', () {
      final emptyDir = Directory(p.join(tempDir.path, 'empty'))..createSync();

      expect(
        () => discoverBrickGenConfig(cwd: emptyDir.path),
        throwsA(
          isA<BrickGenConfigNotFoundException>()
              .having(
                (error) => error.message,
                'message',
                contains('not found'),
              )
              .having(
                (error) => error.searchedPaths,
                'searchedPaths',
                isNotEmpty,
              ),
        ),
      );
    });

    test('throws when explicit config path does not exist', () {
      final projectRoot = Directory(p.join(tempDir.path, 'project'))
        ..createSync();

      expect(
        () => discoverBrickGenConfig(
          cwd: projectRoot.path,
          configPath: 'missing/brick-gen.json',
        ),
        throwsA(isA<BrickGenConfigNotFoundException>()),
      );
    });
  });

  group('collectConfigSearchPaths', () {
    test('returns candidates from start dir up to filesystem root', () {
      final startDir = p.join(Directory.systemTemp.path, 'a', 'b', 'c');
      final candidates = collectConfigSearchPaths(startDir: startDir);

      expect(candidates.first, p.join(startDir, 'brick-gen.json'));
      expect(
        candidates,
        contains(p.join(Directory.systemTemp.path, 'brick-gen.json')),
      );

      final lastCandidate = candidates.last;
      final lastParent = p.dirname(p.dirname(lastCandidate));
      expect(lastParent, p.dirname(lastCandidate));
    });
  });
}
