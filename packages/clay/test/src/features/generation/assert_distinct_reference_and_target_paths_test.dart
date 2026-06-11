import 'dart:io';

import 'package:clay/src/features/generation/assert_distinct_reference_and_target_paths.dart';
import 'package:clay/src/features/generation/generation_exception.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('assertDistinctReferenceAndTargetPaths', () {
    late Directory tempDir;
    late Directory referenceDir;
    late Directory targetDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_distinct_paths_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
      targetDir = Directory(p.join(tempDir.path, 'target'))
        ..createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('allows distinct sibling directories', () {
      expect(
        () => assertDistinctReferenceAndTargetPaths(
          referencePath: referenceDir.path,
          targetPath: targetDir.path,
        ),
        returnsNormally,
      );
    });

    test('throws when reference and target paths are equal', () {
      expect(
        () => assertDistinctReferenceAndTargetPaths(
          referencePath: referenceDir.path,
          targetPath: referenceDir.path,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('must differ'),
          ),
        ),
      );
    });

    test('throws when the target is inside the reference', () {
      final nestedTarget = Directory(p.join(referenceDir.path, 'output'))
        ..createSync(recursive: true);

      expect(
        () => assertDistinctReferenceAndTargetPaths(
          referencePath: referenceDir.path,
          targetPath: nestedTarget.path,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('inside the reference directory'),
          ),
        ),
      );
    });

    test('throws when the reference is inside the target', () {
      final nestedReference = Directory(p.join(targetDir.path, 'reference'))
        ..createSync(recursive: true);

      expect(
        () => assertDistinctReferenceAndTargetPaths(
          referencePath: nestedReference.path,
          targetPath: targetDir.path,
        ),
        throwsA(
          isA<GenerationException>().having(
            (error) => error.message,
            'message',
            contains('inside the target directory'),
          ),
        ),
      );
    });
  });
}
