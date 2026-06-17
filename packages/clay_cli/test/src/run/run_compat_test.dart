import 'dart:io';

import 'package:clay_cli/src/run/run_compat.dart';
import 'package:clay_core/clay.dart' show clayCoreVersion;
import 'package:clay_core/config.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('runCompat', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('clay_run_compat_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('resolves config when environment.clay is omitted', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
''');

      final resolved = await runCompat(cwd: tempDir.path);

      expect(resolved.config.environment.clay.toString(), 'any');
    });

    test('throws when environment.clay excludes the current version', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
environment:
  clay: ^0.2.0
''');

      await expectLater(
        runCompat(cwd: tempDir.path),
        throwsA(
          isA<ClayIncompatibleException>()
              .having(
                (error) => error.currentVersion,
                'currentVersion',
                clayCoreVersion,
              )
              .having(
                (error) => error.requiredConstraint,
                'requiredConstraint',
                '^0.2.0',
              ),
        ),
      );
    });
  });
}
