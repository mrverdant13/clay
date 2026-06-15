import 'dart:io';

import 'package:clay_cli/src/run/run_gen.dart';
import 'package:clay_core/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('runGen', () {
    late Directory tempDir;
    late Directory referenceDir;
    late Directory targetDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_run_gen_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
      targetDir = Directory(p.join(tempDir.path, 'target'));
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('discovers config and generates the template', () async {
      File(p.join(referenceDir.path, 'main.dart')).writeAsStringSync('main\n');

      final result = await runGen(cwd: tempDir.path);

      expect(result.referencePath, referenceDir.path);
      expect(result.targetPath, targetDir.path);
      expect(result.fileCount, 1);
      expect(
        File(p.join(targetDir.path, 'main.dart')).readAsStringSync(),
        'main\n',
      );
    });

    test('tracks excluded files', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
ignore:
  - build/
''');
      File(p.join(referenceDir.path, 'lib', 'main.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('main\n');
      File(p.join(referenceDir.path, 'build', 'output.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ignored\n');

      final result = await runGen(cwd: tempDir.path);

      expect(result.fileCount, 1);
      expect(result.excludedFiles, contains('build/output.txt'));
    });

    test('throws when config cannot be discovered', () async {
      final emptyDir = Directory.systemTemp.createTempSync(
        'clay_run_gen_empty_',
      );
      try {
        await expectLater(
          runGen(cwd: emptyDir.path),
          throwsA(isA<ClayConfigNotFoundException>()),
        );
      } finally {
        emptyDir.deleteSync(recursive: true);
      }
    });
  });

  group('formatGenRunSummary', () {
    test('includes resolved paths and file count', () {
      final lines = formatGenRunSummary(
        const GenRunResult(
          configPath: '/project/clay.yaml',
          projectRoot: '/project',
          referencePath: '/project/reference',
          targetPath: '/project/target',
          fileCount: 3,
          excludedFiles: [],
        ),
      );

      expect(lines, [
        'Reference: /project/reference',
        'Target: /project/target',
        'Files: 3',
      ]);
    });
  });

  group('countTargetFiles', () {
    test('counts files and symlinks under the target directory', () {
      final tempDir = Directory.systemTemp.createTempSync('clay_count_target_');
      try {
        File(p.join(tempDir.path, 'a.txt')).writeAsStringSync('a\n');
        File(p.join(tempDir.path, 'nested', 'b.txt'))
          ..createSync(recursive: true)
          ..writeAsStringSync('b\n');

        expect(countTargetFiles(tempDir.path), 2);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
