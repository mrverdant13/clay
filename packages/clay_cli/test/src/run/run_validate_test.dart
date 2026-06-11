import 'dart:io';

import 'package:clay/clay.dart' show AnnotationIssue;
import 'package:clay/config.dart';
import 'package:clay/validation.dart';
import 'package:clay_cli/src/run/run_validate.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('runValidate', () {
    late Directory tempDir;
    late Directory referenceDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_run_validate_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
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

    test('returns no issues for valid reference files', () async {
      File(p.join(referenceDir.path, 'main.dart')).writeAsStringSync('main\n');

      final result = await runValidate(cwd: tempDir.path);

      expect(result.referencePath, referenceDir.path);
      expect(result.issues, isEmpty);
    });

    test('returns issues for invalid annotation markers', () async {
      File(p.join(referenceDir.path, 'broken.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('/*remove-start*/\n');

      final result = await runValidate(cwd: tempDir.path);

      expect(result.issues, hasLength(1));
      expect(result.issues.single.filePath, 'broken.dart');
    });

    test('throws when config is missing', () async {
      final emptyDir = Directory.systemTemp.createTempSync(
        'clay_validate_empty_',
      );
      try {
        await expectLater(
          runValidate(cwd: emptyDir.path),
          throwsA(isA<ClayConfigNotFoundException>()),
        );
      } finally {
        emptyDir.deleteSync(recursive: true);
      }
    });

    test('throws when reference directory is missing', () async {
      referenceDir.deleteSync(recursive: true);

      await expectLater(
        runValidate(cwd: tempDir.path),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('Reference directory not found'),
          ),
        ),
      );
    });

    test('formatValidateIssues formats filePath:line:column: message', () {
      final lines = formatValidateIssues(const [
        AnnotationIssue(
          filePath: 'broken.dart',
          line: 1,
          column: 1,
          message: 'Unmatched remove-start marker (/* */)',
        ),
      ]);

      expect(
        lines.single,
        'broken.dart:1:1: Unmatched remove-start marker (/* */)',
      );
    });
  });
}
