import 'dart:io';

import 'package:clay/clay.dart';
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

    test('deletes ignored symlinks and prunes empty parents', () async {
      final externalFile = File(p.join(tempDir.path, 'external.txt'))
        ..writeAsStringSync('external');
      Directory(p.join(targetDir.path, 'build')).createSync(recursive: true);
      final ignoredLink = Link(p.join(targetDir.path, 'build', 'link.txt'))
        ..createSync(externalFile.path);

      await processTargetLink(
        link: ignoredLink,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(ignore: const ['build/']),
      );

      expect(ignoredLink.existsSync(), isFalse);
      expect(Directory(p.join(targetDir.path, 'build')).existsSync(), isFalse);
    });

    test('renames symlinks using replacements', () async {
      final externalFile = File(p.join(tempDir.path, 'external.txt'))
        ..writeAsStringSync('external');
      final originalLink = Link(p.join(targetDir.path, 'from_link.txt'))
        ..createSync(externalFile.path);

      await processTargetLink(
        link: originalLink,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
        ),
      );

      expect(originalLink.existsSync(), isFalse);
      final renamedLink = Link(p.join(targetDir.path, 'to_link.txt'));
      expect(renamedLink.existsSync(), isTrue);
      expect(renamedLink.targetSync(), externalFile.path);
    });

    test('renames symlinks over ignored destinations', () async {
      final externalFile = File(p.join(tempDir.path, 'external.txt'))
        ..writeAsStringSync('external');
      final otherExternal = File(p.join(tempDir.path, 'other.txt'))
        ..writeAsStringSync('other');
      Link(p.join(targetDir.path, 'to_link.txt'))
          .createSync(otherExternal.path);
      final sourceLink = Link(p.join(targetDir.path, 'from_link.txt'))
        ..createSync(externalFile.path);

      await processTargetLink(
        link: sourceLink,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
          ignore: const ['to_link.txt'],
        ),
      );

      expect(sourceLink.existsSync(), isFalse);
      final renamedLink = Link(p.join(targetDir.path, 'to_link.txt'));
      expect(renamedLink.existsSync(), isTrue);
      expect(renamedLink.targetSync(), externalFile.path);
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

    test('renames files over ignored destinations', () async {
      File(p.join(targetDir.path, 'to.txt'))
        ..createSync()
        ..writeAsStringSync('ignored');
      final sourceFile = File(p.join(targetDir.path, 'from.txt'))
        ..createSync()
        ..writeAsStringSync('source');

      await processTargetFile(
        file: sourceFile,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(
          replacements: [Replacement(from: RegExp('from'), to: 'to')],
          ignore: const ['to.txt'],
        ),
      );

      expect(sourceFile.existsSync(), isFalse);
      expect(
        File(p.join(targetDir.path, 'to.txt')).readAsStringSync(),
        'source',
      );
    });

    test('renames files over ignored directory destinations', () async {
      Directory(p.join(targetDir.path, 'build')).createSync();
      final sourceFile = File(p.join(targetDir.path, 'from.txt'))
        ..createSync()
        ..writeAsStringSync('source');

      await processTargetFile(
        file: sourceFile,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(
          replacements: [
            Replacement(from: RegExp(r'^from\.txt$'), to: 'build'),
          ],
          ignore: const ['build/'],
        ),
      );

      expect(sourceFile.existsSync(), isFalse);
      expect(
        File(p.join(targetDir.path, 'build')).readAsStringSync(),
        'source',
      );
    });

    test('renames files over ignored non-empty directory destinations',
        () async {
      Directory(p.join(targetDir.path, 'build')).createSync();
      File(p.join(targetDir.path, 'build', 'stale.txt'))
        ..createSync()
        ..writeAsStringSync('stale');
      final sourceFile = File(p.join(targetDir.path, 'from.txt'))
        ..createSync()
        ..writeAsStringSync('source');

      await processTargetFile(
        file: sourceFile,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(
          replacements: [
            Replacement(from: RegExp(r'^from\.txt$'), to: 'build'),
          ],
          ignore: const ['build/'],
        ),
      );

      expect(sourceFile.existsSync(), isFalse);
      expect(
        File(p.join(targetDir.path, 'build')).readAsStringSync(),
        'source',
      );
      expect(
        File(p.join(targetDir.path, 'build', 'stale.txt')).existsSync(),
        isFalse,
      );
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

    test(
      'applies line deletions when relative paths use backslashes',
      () async {
        final file = File(p.join(targetDir.path, 'nested', 'file.txt'))
          ..createSync(recursive: true)
          ..writeAsStringSync('drop\nkeep\n');

        await processTargetFile(
          file: file,
          targetAbsolutePath: targetDir.path,
          config: BrickGenConfig(
            lineDeletions: const [
              LineDeletion(
                filePath: 'nested/file.txt',
                ranges: [LineRange(start: 0, end: 0)],
              ),
            ],
          ),
        );

        expect(file.readAsStringSync(), 'keep\n');
      },
      skip: !Platform.isWindows
          ? 'Path separator normalization is only required on Windows'
          : false,
    );

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

    test('leaves binary files unchanged', () async {
      final bytes = [0xFF, 0xD8, 0xFF, 0x00, 0x01];
      final file = File(p.join(targetDir.path, 'assets', 'logo.jpg'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(bytes);

      await processTargetFile(
        file: file,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(),
      );

      expect(file.readAsBytesSync(), bytes);
    });

    test('skips content transforms for invalid UTF-8 text files', () async {
      final bytes = [0xFF, 0xFE, 0x00];
      final file = File(p.join(targetDir.path, 'notes.txt'))
        ..createSync()
        ..writeAsBytesSync(bytes);

      await processTargetFile(
        file: file,
        targetAbsolutePath: targetDir.path,
        config: BrickGenConfig(),
      );

      expect(file.readAsBytesSync(), bytes);
    });
  });

  group('entityAtPath', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_entity_at_path_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns a link when resolveType reports a link', () {
      final path = p.join(tempDir.path, 'link.txt');

      final entity = entityAtPath(
        path,
        resolveType: (_) => FileSystemEntityType.link,
      );

      expect(entity, isA<Link>());
      expect(entity!.path, path);
    });

    test('returns a link when the path points at an existing file target', () {
      final targetFile = File(p.join(tempDir.path, 'external.txt'))
        ..writeAsStringSync('external');
      final path = p.join(tempDir.path, 'link.txt');
      Link(path).createSync(targetFile.path);

      final entity = entityAtPath(path);

      expect(entity, isA<Link>());
      expect(entity!.path, path);
    });

    test('returns null when resolveType reports an unknown type', () {
      expect(
        entityAtPath(
          p.join(tempDir.path, 'missing.txt'),
          resolveType: (_) => FileSystemEntityType.notFound,
        ),
        isNull,
      );
    });
  });

  group('readFileTextOrNull', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_read_file_text_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('returns null when readContent throws FormatException', () async {
      final file = File(p.join(tempDir.path, 'notes.txt'))..createSync();

      expect(
        await readFileTextOrNull(
          file,
          readContent: (_) async => throw const FormatException('invalid'),
        ),
        isNull,
      );
    });
  });
}
