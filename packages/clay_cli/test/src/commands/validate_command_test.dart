import 'dart:io';

import 'package:clay_cli/clay_cli.dart';
import 'package:clay_cli/src/run/run_validate.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('ValidateCommand', () {
    late _MockLogger logger;
    late Directory tempDir;
    late Directory referenceDir;

    setUpAll(() {
      registerFallbackValue(Level.info);
    });

    setUp(() {
      logger = _MockLogger();
      when(() => logger.level).thenReturn(Level.info);
      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.detail(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);

      tempDir = Directory.systemTemp.createTempSync('clay_validate_command_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
      File(p.join(tempDir.path, 'brick-gen.json')).writeAsStringSync('''
{
  "reference": "reference",
  "target": "target"
}
''');
      File(p.join(referenceDir.path, 'main.dart')).writeAsStringSync('main\n');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exits successfully when reference files are valid', () async {
      final exitCode = await clay(
        args: ['validate', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verifyNever(() => logger.err(any()));
    });

    test('reports issues to stderr and exits with code 1', () async {
      File(p.join(referenceDir.path, 'broken.dart'))
        ..createSync(recursive: true)
        ..writeAsStringSync('/*remove-start*/\n');

      final exitCode = await clay(
        args: ['validate', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, validationIssuesExitCode);
      verify(
        () => logger.err(
          any(
            that: allOf(
              contains('broken.dart'),
              contains('Unmatched remove-start marker'),
            ),
          ),
        ),
      ).called(1);
    });

    test('logs resolved paths when verbose', () async {
      when(() => logger.level).thenReturn(Level.verbose);

      final exitCode = await clay(
        args: ['validate', '--cwd', tempDir.path, '--verbose'],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verify(
        () => logger.detail(
          'Config: ${p.normalize(p.join(tempDir.path, 'brick-gen.json'))}',
        ),
      ).called(1);
      verify(
        () => logger.detail(
          'Reference: ${p.normalize(p.join(tempDir.path, 'reference'))}',
        ),
      ).called(1);
    });

    test('returns a non-zero exit code when config is invalid', () async {
      File(p.join(tempDir.path, 'brick-gen.json')).writeAsStringSync(
        '{invalid',
      );

      final exitCode = await clay(
        args: ['validate', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.software.code);
      verify(
        () => logger.err(any(that: contains('Invalid brick-gen.json'))),
      ).called(1);
    });

    test('returns a non-zero exit code when config is missing', () async {
      final emptyDir = Directory.systemTemp.createTempSync(
        'clay_validate_empty_',
      );
      try {
        final exitCode = await clay(
          args: ['validate', '--cwd', emptyDir.path],
          logger: logger,
        );

        expect(exitCode, ExitCode.software.code);
        verify(
          () => logger.err(any(that: contains('brick-gen.json'))),
        ).called(1);
      } finally {
        emptyDir.deleteSync(recursive: true);
      }
    });

    test('returns a non-zero exit code when reference is missing', () async {
      referenceDir.deleteSync(recursive: true);

      final exitCode = await clay(
        args: ['validate', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.software.code);
      verify(() => logger.err(any(that: contains('Reference directory'))))
          .called(1);
    });
  });
}
