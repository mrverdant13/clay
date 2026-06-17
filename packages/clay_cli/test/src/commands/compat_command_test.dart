import 'dart:io';

import 'package:clay_cli/clay_cli.dart';
import 'package:clay_core/clay.dart' show clayCoreVersion;
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('CompatCommand', () {
    late _MockLogger logger;
    late Directory tempDir;

    setUpAll(() {
      registerFallbackValue(Level.info);
    });

    setUp(() {
      logger = _MockLogger();
      when(() => logger.level).thenReturn(Level.info);
      when(() => logger.info(any())).thenReturn(null);
      when(() => logger.detail(any())).thenReturn(null);
      when(() => logger.err(any())).thenReturn(null);

      tempDir = Directory.systemTemp.createTempSync('clay_compat_command_');
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

    test('is registered and discoverable via compat --help', () async {
      final exitCode = await clay(
        args: ['compat', '--help'],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
    });

    test('exits successfully with no output when config is compatible',
        () async {
      final exitCode = await clay(
        args: ['compat', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verifyNever(() => logger.info(any()));
      verifyNever(() => logger.err(any()));
    });

    test('exits successfully when environment.clay is any', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
environment:
  clay: any
''');

      final exitCode = await clay(
        args: ['compat', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verifyNever(() => logger.err(any()));
    });

    test(
      'exits successfully when environment.clay allows the current version',
      () async {
        File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
environment:
  clay: ^$clayCoreVersion
''');

        final exitCode = await clay(
          args: ['compat', '--cwd', tempDir.path],
          logger: logger,
        );

        expect(exitCode, ExitCode.success.code);
        verifyNever(() => logger.err(any()));
      },
    );

    test(
      'returns a non-zero exit code when environment.clay is incompatible',
      () async {
        File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
environment:
  clay: ^0.2.0
''');

        final exitCode = await clay(
          args: ['compat', '--cwd', tempDir.path],
          logger: logger,
        );

        expect(exitCode, ExitCode.software.code);
        verify(
          () => logger.err(
            any(
              that: allOf(
                contains('The current clay version is $clayCoreVersion'),
                contains('This project requires clay version ^0.2.0'),
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'returns a non-zero exit code when explicit config path is missing',
      () async {
        final exitCode = await clay(
          args: [
            'compat',
            '--config',
            'missing-clay.yaml',
            '--cwd',
            tempDir.path,
          ],
          logger: logger,
        );

        expect(exitCode, ExitCode.software.code);
        verify(
          () => logger.err(
            any(
              that: allOf(
                contains('Config file not found at'),
                contains('missing-clay.yaml'),
              ),
            ),
          ),
        ).called(1);
      },
    );

    test(
      'returns a non-zero exit code when environment.clay is invalid',
      () async {
        File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
environment:
  clay: not-a-version
''');

        final exitCode = await clay(
          args: ['compat', '--cwd', tempDir.path],
          logger: logger,
        );

        expect(exitCode, ExitCode.software.code);
        verify(() => logger.err(any(that: contains('Invalid environment'))))
            .called(1);
      },
    );

    test('returns a non-zero exit code when config is missing', () async {
      final emptyDir =
          Directory.systemTemp.createTempSync('clay_compat_empty_');
      try {
        final exitCode = await clay(
          args: ['compat', '--cwd', emptyDir.path],
          logger: logger,
        );

        expect(exitCode, ExitCode.software.code);
        verify(
          () => logger.err(any(that: contains('clay.yaml'))),
        ).called(1);
      } finally {
        emptyDir.deleteSync(recursive: true);
      }
    });

    test('returns usage exit code for invalid flags', () async {
      final exitCode = await clay(
        args: ['compat', '--bogus'],
        logger: logger,
      );

      expect(exitCode, ExitCode.usage.code);
      verify(() => logger.err(any(that: contains('Could not find')))).called(1);
    });
  });
}
