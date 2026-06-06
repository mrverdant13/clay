import 'package:clay_cli/clay_cli.dart';
import 'package:mason/mason.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _FakeCommand extends ClayCommand {
  @override
  String get name => 'fake-command';

  @override
  String get description => 'Fake command';
}

void main() {
  group('ClayCommand', () {
    late Logger logger;
    late ClayCommandRunner runner;
    late ClayCommand command;

    setUp(() {
      logger = _MockLogger();
      runner = ClayCommandRunner(
        logger: logger,
      );
      command = _FakeCommand();
      runner.addCommand(command);
      registerFallbackValue(logger);
    });

    group('runner', () {
      test('returns the wrapping command runner', () {
        expect(command.runner, runner);
      });
    });

    group('logger', () {
      test('returns the logger from the command runner', () {
        expect(command.logger, logger);
        expect(command.logger, runner.logger);
      });
    });
  });
}
