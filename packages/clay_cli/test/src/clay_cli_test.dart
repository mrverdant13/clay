import 'package:clay_cli/clay_cli.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('public API', () {
    test('exports the CLI entrypoint', () {
      expect(clay, isA<Function>());
    });

    test('exports command types', () {
      expect(GenCommand, isA<Type>());
      expect(PreviewCommand, isA<Type>());
      expect(ValidateCommand, isA<Type>());
    });
  });

  group('clay', () {
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
    });

    test('can be invoked', () async {
      final exitCode = await clay(
        args: ['--help'],
        logger: logger,
      );
      expect(exitCode, ExitCode.success.code);
    });
  });
}
