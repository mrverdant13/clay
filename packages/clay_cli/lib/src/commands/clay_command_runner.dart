import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:clay_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:meta/meta.dart';

/// {@template clay_cli.clay_command_runner}
/// The runner for the Clay CLI.
/// {@endtemplate}
class ClayCommandRunner extends CommandRunner<int> {
  /// {@macro clay_cli.clay_command_runner}
  ClayCommandRunner({
    required this.logger,
  }) : super(
          packageName,
          'A toolchain for authoring Mason brick templates from reference '
          'projects.',
        ) {
    argParser
      ..addFlag(
        versionOptionName,
        negatable: false,
        help: 'Print the current version.',
      )
      ..addFlag(
        verboseOptionName,
        help: 'Verbose logging.',
      )
      ..addOption(
        configOptionName,
        help: 'Path to brick-gen.json (skips discovery).',
      )
      ..addOption(
        cwdOptionName,
        help: 'Working directory for config discovery.',
      );
  }

  /// Option name for `--version`.
  static const versionOptionName = 'version';

  /// Option name for `--verbose`.
  static const verboseOptionName = 'verbose';

  /// Option name for `--config`.
  static const configOptionName = 'config';

  /// Option name for `--cwd`.
  static const cwdOptionName = 'cwd';

  /// The logger for the command runner.
  final Logger logger;

  /// Parses [args] without running a command.
  @visibleForTesting
  ArgResults parseArguments(Iterable<String> args) => parse(args);

  @override
  void printUsage() => logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);
      if (argResults[verboseOptionName] == true) {
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
    if (topLevelResults[versionOptionName] == true) {
      logger.info(packageVersion);
      return ExitCode.success.code;
    }

    return super.runCommand(topLevelResults);
  }
}
