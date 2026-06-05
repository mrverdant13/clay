import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:clay_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template clay_cli.clay_command_runner}
/// The runner for the Clay CLI.
/// {@endtemplate}
class ClayCommandRunner extends CommandRunner<int> {
  /// {@macro clay_cli.clay_command_runner}
  ClayCommandRunner({Logger? logger})
    : logger = logger ?? Logger(),
      super(
        packageName,
        'A toolchain for authoring Mason brick templates from reference '
        'projects.',
      ) {
    argParser
      ..addFlag('version', negatable: false, help: 'Print the current version.')
      ..addFlag('verbose', help: 'Verbose logging.');
  }

  /// The logger for the command runner.
  final Logger logger;

  @override
  void printUsage() => logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);
      if (argResults['verbose'] == true) {
        logger.level = Level.verbose;
      }
      return await runCommand(argResults) ?? ExitCode.success.code;
    } on FormatException catch (e) {
      logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      logger
        ..err(e.message)
        ..info('')
        ..info(e.usage);
      return ExitCode.usage.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      logger.info(packageVersion);
      return ExitCode.success.code;
    }

    if (topLevelResults.command == null) {
      logger.err('No command specified.');
      printUsage();
      return ExitCode.usage.code;
    }

    return super.runCommand(topLevelResults);
  }
}
