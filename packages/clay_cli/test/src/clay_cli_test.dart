import 'package:clay_cli/clay_cli.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
  group('public API', () {
    test('exports documented programmatic APIs', () {
      expect(loadBrickGenConfig, isA<Function>());
      expect(resolveReferenceContent, isA<Function>());
      expect(generateTemplate, isA<Function>());
      expect(validateAnnotations, isA<Function>());
    });

    test('exports entity types used by programmatic APIs', () {
      expect(BrickGenConfig, isA<Type>());
      expect(AnnotationIssue, isA<Type>());
    });

    test('exports the CLI entrypoint', () {
      expect(clay, isA<Function>());
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
