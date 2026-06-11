import 'dart:io';

import 'package:clay/src/features/generation/copy_directory.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('copyDirectory', () {
    late Directory tempDir;
    late Directory sourceDir;
    late Directory destinationDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_copy_dir_');
      sourceDir = Directory(p.join(tempDir.path, 'source'))
        ..createSync(recursive: true);
      destinationDir = Directory(p.join(tempDir.path, 'destination'));
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('copies files and nested directories', () async {
      File(p.join(sourceDir.path, 'root.txt')).writeAsStringSync('root');
      Directory(p.join(sourceDir.path, 'nested')).createSync();
      File(p.join(sourceDir.path, 'nested', 'child.txt'))
          .writeAsStringSync('child');

      await copyDirectory(source: sourceDir, destination: destinationDir);

      expect(
        File(p.join(destinationDir.path, 'root.txt')).readAsStringSync(),
        'root',
      );
      expect(
        File(p.join(destinationDir.path, 'nested', 'child.txt'))
            .readAsStringSync(),
        'child',
      );
    });

    test('creates an empty destination directory', () async {
      await copyDirectory(source: sourceDir, destination: destinationDir);

      expect(destinationDir.existsSync(), isTrue);
      expect(destinationDir.listSync(), isEmpty);
    });

    test('copies symlinks without following them', () async {
      final externalFile = File(p.join(tempDir.path, 'external.txt'))
        ..writeAsStringSync('external');
      final externalDir = Directory(p.join(tempDir.path, 'external_dir'))
        ..createSync();
      Link(p.join(sourceDir.path, 'linked.txt')).createSync(externalFile.path);
      Link(p.join(sourceDir.path, 'linked_dir')).createSync(externalDir.path);

      await copyDirectory(source: sourceDir, destination: destinationDir);

      final copiedLink = Link(p.join(destinationDir.path, 'linked.txt'));
      expect(copiedLink.existsSync(), isTrue);
      expect(copiedLink.targetSync(), externalFile.path);
      expect(
        File(p.join(destinationDir.path, 'external.txt')).existsSync(),
        isFalse,
      );

      final copiedDirLink = Link(p.join(destinationDir.path, 'linked_dir'));
      expect(copiedDirLink.existsSync(), isTrue);
      expect(
        Directory(p.join(destinationDir.path, 'external_dir')).existsSync(),
        isFalse,
      );
    });
  });

  group('copyFileToDestination', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_copy_file_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('creates missing parent directories', () async {
      final sourceFile = File(p.join(tempDir.path, 'source.txt'))
        ..writeAsStringSync('payload');
      final destinationPath = p.join(
        tempDir.path,
        'missing',
        'nested',
        'out.txt',
      );

      await copyFileToDestination(
        file: sourceFile,
        destinationPath: destinationPath,
      );

      expect(File(destinationPath).readAsStringSync(), 'payload');
    });
  });
}
