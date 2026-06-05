import 'package:args/command_runner.dart';
import 'package:clay_cli/src/commands/clay_command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template clay_cli.clay_command}
/// A base Clay command.
/// {@endtemplate}
abstract class ClayCommand extends Command<int> {
  /// {@macro clay_cli.clay_command}
  ClayCommand();

  @override
  ClayCommandRunner get runner => super.runner! as ClayCommandRunner;

  /// The logger for the command.
  Logger get logger => runner.logger;
}
