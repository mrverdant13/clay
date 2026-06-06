import 'package:clay_cli/clay_cli.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

void main() {
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
