import 'package:args/command_runner.dart';
import 'package:clay_cli/src/commands/clay_command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template clay_cli.clay_command}
/// A base Clay command.
/// {@endtemplate}
abstract class ClayCommand extends Command<int> {
  /// {@macro clay_cli.clay_command}
  ClayCommand() {
    argParser
      ..addOption(
        referenceOptionName,
        help: 'Overrides config → reference.',
      )
      ..addOption(
        targetOptionName,
        help: 'Overrides config → target.',
      );
  }

  /// Option name for `--reference`.
  static const referenceOptionName = 'reference';

  /// Option name for `--target`.
  static const targetOptionName = 'target';

  @override
  ClayCommandRunner get runner => super.runner! as ClayCommandRunner;

  /// The logger for the command.
  Logger get logger => runner.logger;

  /// {@macro clay_cli.clay_command_runner.config_path}
  String? get configPath => runner.configPath;

  /// {@macro clay_cli.clay_command_runner.cwd}
  String? get cwd => runner.cwd;

  /// Explicit `--reference` override, or `null` when omitted.
  String? get referenceOverride => argResults?.option(referenceOptionName);

  /// Explicit `--target` override, or `null` when omitted.
  String? get targetOverride => argResults?.option(targetOptionName);
}
