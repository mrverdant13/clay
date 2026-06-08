import 'dart:io';

import 'package:clay_cli/clay_cli.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('GenCommand', () {
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

      tempDir = Directory.systemTemp.createTempSync('clay_gen_command_');
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

    test('generates template and prints summary to stdout', () async {
      final exitCode = await clay(
        args: ['gen', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verify(
        () => logger.info(
          'Reference: ${p.normalize(p.join(tempDir.path, 'reference'))}',
        ),
      ).called(1);
      verify(
        () => logger.info(
          'Target: ${p.normalize(p.join(tempDir.path, 'target'))}',
        ),
      ).called(1);
      verify(() => logger.info('Files: 1')).called(1);
      expect(
        File(p.join(tempDir.path, 'target', 'main.dart')).existsSync(),
        isTrue,
      );
    });

    test('runs as the default command when no subcommand is given', () async {
      final exitCode = await clay(
        args: ['--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verify(() => logger.info('Files: 1')).called(1);
    });

    test('logs excluded files when verbose', () async {
      File(p.join(tempDir.path, 'brick-gen.json')).writeAsStringSync('''
{
  "reference": "reference",
  "target": "target",
  "ignore": ["build/"]
}
''');
      File(p.join(referenceDir.path, 'build', 'output.txt'))
        ..createSync(recursive: true)
        ..writeAsStringSync('ignored\n');

      when(() => logger.level).thenReturn(Level.verbose);

      final exitCode = await clay(
        args: ['gen', '--cwd', tempDir.path, '--verbose'],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verify(() => logger.detail('Excluded: build/output.txt')).called(1);
    });

    test('returns a non-zero exit code when config is missing', () async {
      final emptyDir = Directory.systemTemp.createTempSync('clay_gen_empty_');
      try {
        final exitCode = await clay(
          args: ['gen', '--cwd', emptyDir.path],
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
        args: ['gen', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.software.code);
      verify(() => logger.err(any(that: contains('Reference directory'))))
          .called(1);
    });
  });
}
