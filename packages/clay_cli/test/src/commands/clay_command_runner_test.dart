import 'dart:async';

import 'package:args/command_runner.dart';
import 'package:clay_cli/clay_cli.dart';
import 'package:clay_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockLogger extends Mock implements Logger {}

class FakeCommand extends ClayCommand {
  FakeCommand({
    required Future<void> Function() run,
  })  : _run = run,
        super();

  final Future<void> Function() _run;

  @override
  String get name => 'fake-command';

  @override
  String get description => 'Fake command';

  @override
  Future<int> run() async {
    await _run();
    return 0;
  }
}

void main() {
  group('ClayCommandRunner', () {
    late Logger logger;

    setUp(() {
      logger = _MockLogger();
    });

    test('can be instantiated', () {
      final runner = ClayCommandRunner(
        logger: logger,
      );
      expect(runner, isNotNull);
    });

    test('printUsage prints usage', () {
      final runner = ClayCommandRunner(
        logger: logger,
      )..printUsage();

      verify(() => logger.info(runner.usage)).called(1);
    });

    test('--verbose sets logger level to verbose', () async {
      final runner = ClayCommandRunner(
        logger: logger,
      );

      final exitCode = await runner.run(const ['--verbose', '--version']);
      expect(exitCode, ExitCode.success.code);
      verify(() => logger.level = Level.verbose).called(1);
    });

    test('parse reads --config and --cwd global options', () {
      final runner = ClayCommandRunner(
        logger: logger,
      )..addCommand(
          FakeCommand(
            run: () async {},
          ),
        );

      final results = runner.parse(const [
        '--config',
        'brick-gen.json',
        '--cwd',
        '/tmp/project',
        'fake-command',
      ]);

      expect(
        results.option(ClayCommandRunner.configOptionName),
        'brick-gen.json',
      );
      expect(
        results.option(ClayCommandRunner.cwdOptionName),
        '/tmp/project',
      );
      expect(results.command?.name, 'fake-command');
    });

    test('usage documents global flags', () {
      final runner = ClayCommandRunner(
        logger: logger,
      )
        ..addCommand(GenCommand())
        ..addCommand(ValidateCommand());

      expect(runner.usage, contains('--config'));
      expect(runner.usage, contains('--cwd'));
      expect(runner.usage, contains('verbose'));
      expect(runner.usage, contains('--version'));
      expect(runner.usage, contains('gen'));
      expect(runner.usage, contains('validate'));
    });

    test('--version prints package version and exits successfully', () async {
      final runner = ClayCommandRunner(
        logger: logger,
      );

      final exitCode = await runner.run(const ['--version']);

      expect(exitCode, ExitCode.success.code);
      verify(() => logger.info(packageVersion)).called(1);
    });

    test('prints error message and usage on $FormatException', () async {
      final subCommand = FakeCommand(
        run: () async {
          throw const FormatException('Invalid command');
        },
      );
      final runner = ClayCommandRunner(
        logger: logger,
      )..addCommand(subCommand);

      await runner.run(const ['fake-command']);
      verify(() => logger.err('Invalid command')).called(1);
      verify(() => logger.info('')).called(1);
      verify(() => logger.info(runner.usage)).called(1);
    });

    test('prints error message and usage on $UsageException', () async {
      final runner = ClayCommandRunner(
        logger: logger,
      );
      final subCommand = FakeCommand(
        run: () async {
          throw UsageException('Invalid command', runner.usage);
        },
      );
      runner.addCommand(subCommand);
      await runner.run(const ['fake-command']);
      verify(() => logger.err('Invalid command')).called(1);
      verify(() => logger.info('')).called(1);
      verify(() => logger.info(runner.usage)).called(1);
    });
  });
}
