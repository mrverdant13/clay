import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/entities/replacement.dart';
import 'package:clay_cli/src/features/generation/process_target_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('processTargetFile', () {
    late Directory tempDir;
    late Directory targetDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_process_file_');
      targetDir = Directory(p.join(tempDir.path, 'target'))
        ..createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('deletes ignored files and prunes empty parents', () async {
      final ignoredFile = File(p.join(targetDir.path, 'build', 'output.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ignored');

      await processTargetFile(
        file: ignoredFile,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(ignore: const ['build/']),
      );

      expect(ignoredFile.existsSync(), isFalse);
      expect(Directory(p.join(targetDir.path, 'build')).existsSync(), isFalse);
    });

    test('renames files using replacements', () async {
      final originalFile = File(p.join(targetDir.path, 'from.txt'))
        ..createSync()
        ..writeAsStringSync('content');

      await processTargetFile(
        file: originalFile,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
      );

      expect(originalFile.existsSync(), isFalse);
      expect(File(p.join(targetDir.path, 'to.txt')).existsSync(), isTrue);
    });

    test('renames files into nested directories', () async {
      final originalFile = File(p.join(targetDir.path, 'flat.txt'))
        ..createSync()
        ..writeAsStringSync('content');

      await processTargetFile(
        file: originalFile,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(
          replacements: [
            Replacement(
              from: RegExp(r'^flat\.txt$'),
              to: 'nested/deep/flat.txt',
            ),
          ],
        ),
      );

      expect(originalFile.existsSync(), isFalse);
      expect(
        File(p.join(targetDir.path, 'nested', 'deep', 'flat.txt')).existsSync(),
        isTrue,
      );
    });

    test('applies content transforms to non-binary files', () async {
      final file = File(p.join(targetDir.path, 'file.txt'))
        ..createSync()
        ..writeAsStringSync('line\n/*drop*/\nmore\n');

      await processTargetFile(
        file: file,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(),
      );

      expect(file.readAsStringSync(), 'line\n');
    });
  });
}
