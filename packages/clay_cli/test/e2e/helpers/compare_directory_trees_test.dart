import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../e2e/e2e/helpers/compare_directory_trees.dart';

void main() {
  group('listRelativeFiles', () {
    test('returns an empty list when the root directory is missing', () {
      final missing = Directory(
        p.join(
          Directory.systemTemp.path,
          'clay_missing_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );

      expect(listRelativeFiles(missing), isEmpty);
    });

    test('returns an empty list for an empty directory', () {
      final root = Directory.systemTemp.createTempSync('clay_empty_root_');
      addTearDown(() {
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      expect(listRelativeFiles(root), isEmpty);
    });

    test('lists nested files using forward slashes', () {
      final root = Directory.systemTemp.createTempSync('clay_list_root_');
      addTearDown(() {
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      File(p.join(root.path, 'top.txt')).writeAsStringSync('top');
      final nestedDir = Directory(p.join(root.path, 'nested'))
        ..createSync(recursive: true);
      File(p.join(nestedDir.path, 'leaf.txt')).writeAsStringSync('leaf');

      expect(
        listRelativeFiles(root),
        ['nested/leaf.txt', 'top.txt'],
      );
    });
  });

  group('listGoldenLogicalPaths', () {
    test('returns an empty list when the root directory is missing', () {
      final missing = Directory(
        p.join(
          Directory.systemTemp.path,
          'clay_missing_golden_${DateTime.now().microsecondsSinceEpoch}',
        ),
      );

      expect(listGoldenLogicalPaths(missing), isEmpty);
    });

    test('maps .golden files to logical output paths', () {
      final root = Directory.systemTemp.createTempSync('clay_golden_root_');
      addTearDown(() {
        if (root.existsSync()) {
          root.deleteSync(recursive: true);
        }
      });

      final libDir = Directory(p.join(root.path, 'lib', 'app'))
        ..createSync(recursive: true);
      File(p.join(libDir.path, 'widget.dart.golden')).writeAsStringSync('a');
      final templatesDir = Directory(p.join(root.path, 'templates'))
        ..createSync(recursive: true);
      File(p.join(templatesDir.path, 'model.html')).writeAsStringSync('b');

      expect(
        listGoldenLogicalPaths(root),
        ['lib/app/widget.dart', 'templates/model.html'],
      );
    });
  });

  group('expectDirectoryTreesMatch', () {
    late Directory expectedRoot;
    late Directory actualRoot;

    setUp(() {
      expectedRoot = Directory.systemTemp.createTempSync('clay_expected_tree_');
      actualRoot = Directory.systemTemp.createTempSync('clay_actual_tree_');
    });

    tearDown(() {
      for (final dir in [expectedRoot, actualRoot]) {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      }
    });

    test('passes when golden and actual trees match', () {
      final expectedLib = Directory(p.join(expectedRoot.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(expectedLib.path, 'main.dart.golden'))
          .writeAsStringSync('generated');

      final actualLib = Directory(p.join(actualRoot.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(actualLib.path, 'main.dart')).writeAsStringSync('generated');

      expect(
        () => expectDirectoryTreesMatch(
          expected: expectedRoot,
          actual: actualRoot,
        ),
        returnsNormally,
      );
    });

    test('fails when the actual tree is missing expected files', () {
      final expectedLib = Directory(p.join(expectedRoot.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(expectedLib.path, 'main.dart.golden'))
          .writeAsStringSync('generated');

      expect(
        () => expectDirectoryTreesMatch(
          expected: expectedRoot,
          actual: actualRoot,
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('fails when the actual tree has unexpected files', () {
      final actualLib = Directory(p.join(actualRoot.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(actualLib.path, 'main.dart')).writeAsStringSync('generated');

      expect(
        () => expectDirectoryTreesMatch(
          expected: expectedRoot,
          actual: actualRoot,
        ),
        throwsA(isA<TestFailure>()),
      );
    });

    test('fails when file contents differ', () {
      final expectedLib = Directory(p.join(expectedRoot.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(expectedLib.path, 'main.dart.golden'))
          .writeAsStringSync('expected');

      final actualLib = Directory(p.join(actualRoot.path, 'lib'))
        ..createSync(recursive: true);
      File(p.join(actualLib.path, 'main.dart')).writeAsStringSync('actual');

      expect(
        () => expectDirectoryTreesMatch(
          expected: expectedRoot,
          actual: actualRoot,
        ),
        throwsA(
          predicate<TestFailure>(
            (failure) => failure.message?.contains('Content mismatch') ?? false,
          ),
        ),
      );
    });

    test('resolves non-suffixed golden files without remapping', () {
      File(p.join(expectedRoot.path, 'schema.sql')).writeAsStringSync('sql');
      File(p.join(actualRoot.path, 'schema.sql')).writeAsStringSync('sql');

      expect(
        () => expectDirectoryTreesMatch(
          expected: expectedRoot,
          actual: actualRoot,
        ),
        returnsNormally,
      );
    });
  });
}
