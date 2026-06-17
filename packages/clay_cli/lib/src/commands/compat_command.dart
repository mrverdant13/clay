import 'package:clay_cli/src/commands/clay_command.dart';
import 'package:clay_cli/src/run/run_compat.dart';
import 'package:clay_core/config.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template clay_cli.compat_command}
/// Checks whether the installed Clay version satisfies `environment.clay`.
/// {@endtemplate}
class CompatCommand extends ClayCommand {
  /// {@macro clay_cli.compat_command}
  CompatCommand();

  /// The command name for `clay compat`.
  static const String commandName = 'compat';

  @override
  String get name => commandName;

  @override
  String get description =>
      'Check whether the installed Clay version satisfies environment.clay.';

  @override
  Future<int> run() async {
    try {
      await runCompat(configPath: configPath, cwd: cwd);
      return ExitCode.success.code;
    } on ClayConfigNotFoundException catch (error) {
      logger.err(error.toString());
      return ExitCode.software.code;
    } on ClayConfigException catch (error) {
      logger.err(error.message);
      return ExitCode.software.code;
    } on ClayIncompatibleException catch (error) {
      logger.err(error.toString());
      return ExitCode.software.code;
    }
  }
}
