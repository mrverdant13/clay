import 'dart:io';

import 'package:clay_cli/src/features/generation/prune_empty_directories.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('pruneEmptyParentDirectories', () {
    late Directory tempDir;
    late Directory stopAt;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_prune_dir_');
      stopAt = Directory(p.join(tempDir.path, 'target'))
        ..createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('removes empty parents up to stopAt', () {
      Directory(p.join(stopAt.path, 'a', 'b', 'c'))
        ..createSync(recursive: true)
        ..deleteSync();

      pruneEmptyParentDirectories(
        startingDirectory: Directory(p.join(stopAt.path, 'a', 'b')),
        stopAt: stopAt,
      );

      expect(Directory(p.join(stopAt.path, 'a')).existsSync(), isFalse);
      expect(Directory(p.join(stopAt.path, 'a', 'b')).existsSync(), isFalse);
      expect(stopAt.existsSync(), isTrue);
    });

    test('stops when a non-empty directory is found', () {
      final parent = Directory(p.join(stopAt.path, 'keep', 'empty'))
        ..createSync(recursive: true);
      File(p.join(stopAt.path, 'keep', 'file.txt')).writeAsStringSync('data');
      parent.deleteSync();

      pruneEmptyParentDirectories(
        startingDirectory: Directory(p.join(stopAt.path, 'keep', 'empty')),
        stopAt: stopAt,
      );

      expect(Directory(p.join(stopAt.path, 'keep')).existsSync(), isTrue);
      expect(
        Directory(p.join(stopAt.path, 'keep', 'empty')).existsSync(),
        isFalse,
      );
    });

    test('does not delete stopAt even when empty', () {
      pruneEmptyParentDirectories(
        startingDirectory: stopAt,
        stopAt: stopAt,
      );

      expect(stopAt.existsSync(), isTrue);
    });
  });
}
