import 'dart:io';

import 'package:clay/clay.dart';
import 'package:clay_cli/src/features/generation/process_target_file.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('processTargetFile path renames', () {
    late Directory tempDir;
    late Directory targetDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync(
        'clay_process_file_path_renames_',
      );
      targetDir = Directory(p.join(tempDir.path, 'target'))
        ..createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    final replacementConfig = BrickGenConfig(
      replacements: [Replacement(from: RegExp('from'), to: 'to')],
    );

    test('renames the file name segment only', () async {
      final originalFile = File(p.join(targetDir.path, 'from-file.txt'))
        ..createSync()
        ..writeAsStringSync('content');

      await processTargetFile(
        file: originalFile,
        targetAbsolutePath: targetDir.path,
        config: replacementConfig,
      );

      expect(originalFile.existsSync(), isFalse);
      expect(File(p.join(targetDir.path, 'to-file.txt')).existsSync(), isTrue);
    });

    test('renames a directory segment in the path', () async {
      final originalFile = File(p.join(targetDir.path, 'from', 'file.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('content');

      await processTargetFile(
        file: originalFile,
        targetAbsolutePath: targetDir.path,
        config: replacementConfig,
      );

      expect(originalFile.existsSync(), isFalse);
      expect(
        File(p.join(targetDir.path, 'to', 'file.txt')).existsSync(),
        isTrue,
      );
    });

    test('renames both directory and file name segments', () async {
      final originalFile = File(p.join(targetDir.path, 'from', 'from.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('content');

      await processTargetFile(
        file: originalFile,
        targetAbsolutePath: targetDir.path,
        config: replacementConfig,
      );

      expect(originalFile.existsSync(), isFalse);
      expect(
        File(p.join(targetDir.path, 'to', 'to.txt')).existsSync(),
        isTrue,
      );
    });
  });
}
