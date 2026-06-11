import 'dart:io';

import 'package:clay_cli/clay_cli.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('PreviewCommand', () {
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

      tempDir = Directory.systemTemp.createTempSync('clay_preview_command_');
      referenceDir = Directory(p.join(tempDir.path, 'reference'))
        ..createSync(recursive: true);
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('''
reference: reference
target: target
replacements:
  - from: Widget
    to: "{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}{{^use_riverpod}}StatelessWidget{{/use_riverpod}}"
''');

      File(p.join(referenceDir.path, 'widget.dart')).writeAsStringSync('''
class App extends Widget {
  /*remove-start*/
  // scaffold
  /*remove-end*/
}
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exits successfully for a valid preview request', () async {
      final exitCode = await clay(
        args: [
          'preview',
          '--cwd',
          tempDir.path,
          '--file',
          'widget.dart',
          '--template-only',
        ],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verifyNever(() => logger.err(any()));
    });

    test('logs resolved paths when verbose', () async {
      when(() => logger.level).thenReturn(Level.verbose);

      final exitCode = await clay(
        args: [
          'preview',
          '--cwd',
          tempDir.path,
          '--file',
          'widget.dart',
          '--template-only',
          '--verbose',
        ],
        logger: logger,
      );

      expect(exitCode, ExitCode.success.code);
      verify(
        () => logger.detail(
          'Config: ${p.normalize(p.join(tempDir.path, 'clay.yaml'))}',
        ),
      ).called(1);
      verify(
        () => logger.detail(
          'Reference: ${p.normalize(p.join(tempDir.path, 'reference'))}',
        ),
      ).called(1);
    });

    test('returns usage exit code when --file is missing', () async {
      final exitCode = await clay(
        args: ['preview', '--cwd', tempDir.path],
        logger: logger,
      );

      expect(exitCode, ExitCode.usage.code);
      verify(
        () => logger.err(any(that: contains('Missing required --file'))),
      ).called(1);
    });

    test('returns usage exit code for invalid --vars', () async {
      final exitCode = await clay(
        args: [
          'preview',
          '--cwd',
          tempDir.path,
          '--file',
          'widget.dart',
          '--vars',
          'not-a-pair',
        ],
        logger: logger,
      );

      expect(exitCode, ExitCode.usage.code);
      verify(
        () => logger.err(any(that: contains('Invalid --vars entry'))),
      ).called(1);
    });

    test('returns a non-zero exit code when config is invalid', () async {
      File(p.join(tempDir.path, 'clay.yaml')).writeAsStringSync('{invalid');

      final exitCode = await clay(
        args: [
          'preview',
          '--cwd',
          tempDir.path,
          '--file',
          'widget.dart',
        ],
        logger: logger,
      );

      expect(exitCode, ExitCode.software.code);
      verify(
        () => logger.err(any(that: contains('Invalid clay.yaml'))),
      ).called(1);
    });

    test('returns a non-zero exit code when config is missing', () async {
      final emptyDir = Directory.systemTemp.createTempSync(
        'clay_preview_empty_',
      );
      try {
        final exitCode = await clay(
          args: [
            'preview',
            '--cwd',
            emptyDir.path,
            '--file',
            'widget.dart',
          ],
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

    test('returns a non-zero exit code when reference is missing', () async {
      referenceDir.deleteSync(recursive: true);

      final exitCode = await clay(
        args: [
          'preview',
          '--cwd',
          tempDir.path,
          '--file',
          'widget.dart',
        ],
        logger: logger,
      );

      expect(exitCode, ExitCode.software.code);
      verify(() => logger.err(any(that: contains('Reference directory'))))
          .called(1);
    });

    test('returns a non-zero exit code when the file is missing', () async {
      final exitCode = await clay(
        args: [
          'preview',
          '--cwd',
          tempDir.path,
          '--file',
          'missing.dart',
        ],
        logger: logger,
      );

      expect(exitCode, ExitCode.software.code);
      verify(() => logger.err(any(that: contains('File not found')))).called(1);
    });
  });
}
