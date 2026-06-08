import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:clay_cli/src/commands/gen_command.dart';
import 'package:clay_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';

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

  @override
  void printUsage() => logger.info(usage);

  /// {@template clay_cli.clay_command_runner.config_path}
  /// The path to the config file.
  /// {@endtemplate}
  late final String? configPath;

  /// {@template clay_cli.clay_command_runner.cwd}
  /// The working directory for config discovery.
  /// {@endtemplate}
  late final String? cwd;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);
      configPath = argResults.option(configOptionName);
      cwd = argResults.option(cwdOptionName);
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

    if (topLevelResults.command == null) {
      if (topLevelResults.flag('help') || topLevelResults.rest.isNotEmpty) {
        return super.runCommand(topLevelResults);
      }

      return runCommand(parse(_defaultGenInvocation(topLevelResults)));
    }

    return super.runCommand(topLevelResults);
  }

  List<String> _defaultGenInvocation(ArgResults topLevelResults) {
    final args = <String>[];
    if (topLevelResults[verboseOptionName] == true) {
      args.add('--$verboseOptionName');
    }
    final config = topLevelResults.option(configOptionName);
    if (config != null) {
      args.addAll(['--$configOptionName', config]);
    }
    final workingDirectory = topLevelResults.option(cwdOptionName);
    if (workingDirectory != null) {
      args.addAll(['--$cwdOptionName', workingDirectory]);
    }
    args.add(GenCommand.commandName);
    args.addAll(topLevelResults.rest);
    return args;
  }
}
