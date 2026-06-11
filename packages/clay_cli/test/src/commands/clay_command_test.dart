import 'package:clay_cli/clay_cli.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class _FakeCommand extends ClayCommand {
  @override
  String get name => 'fake-command';

  @override
  String get description => 'Fake command';
}

class _RecordingCommand extends ClayCommand {
  String? capturedConfigPath;
  String? capturedCwd;
  String? capturedReferenceOverride;
  String? capturedTargetOverride;

  @override
  String get name => 'recording-command';

  @override
  String get description => 'Records parsed CLI flags';

  @override
  Future<int> run() async {
    capturedConfigPath = configPath;
    capturedCwd = cwd;
    capturedReferenceOverride = referenceOverride;
    capturedTargetOverride = targetOverride;
    return 0;
  }
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

    group('flag getters', () {
      late _RecordingCommand recordingCommand;

      setUp(() {
        recordingCommand = _RecordingCommand();
        runner.addCommand(recordingCommand);
      });

      test('return null when flags are omitted', () async {
        await runner.run(const ['recording-command']);

        expect(recordingCommand.capturedConfigPath, isNull);
        expect(recordingCommand.capturedCwd, isNull);
        expect(recordingCommand.capturedReferenceOverride, isNull);
        expect(recordingCommand.capturedTargetOverride, isNull);
      });

      test('expose parsed global and shared flags', () async {
        await runner.run(const [
          '--config',
          'brick-gen.json',
          '--cwd',
          '/tmp/project',
          'recording-command',
          '--reference',
          'custom-reference',
          '--target',
          'custom-target',
        ]);

        expect(recordingCommand.capturedConfigPath, 'brick-gen.json');
        expect(recordingCommand.capturedCwd, '/tmp/project');
        expect(recordingCommand.capturedReferenceOverride, 'custom-reference');
        expect(recordingCommand.capturedTargetOverride, 'custom-target');
      });
    });

    group('usage', () {
      test('documents shared command flags', () {
        expect(command.usage, contains('--reference'));
        expect(command.usage, contains('--target'));
      });
    });
  });
}
