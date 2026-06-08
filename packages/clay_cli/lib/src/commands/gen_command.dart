import 'package:clay_cli/src/commands/clay_command.dart';
import 'package:clay_cli/src/commands/clay_command_runner.dart';
import 'package:clay_cli/src/features/config/brick_gen_config_exception.dart';
import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:clay_cli/src/features/generation/run_gen.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template clay_cli.gen_command}
/// Generates the template from the reference project.
/// {@endtemplate}
class GenCommand extends ClayCommand {
  /// {@macro clay_cli.gen_command}
  GenCommand();

  /// The command name for `clay gen`.
  static const commandName = ClayCommandRunner.defaultCommandName;

  @override
  String get name => commandName;

  @override
  String get description => 'Generate the template from the reference project.';

  @override
  Future<int> run() async {
    try {
      final result = await runGen(
        configPath: configPath,
        cwd: cwd,
        referenceOverride: referenceOverride,
        targetOverride: targetOverride,
        onIgnoredFile: logger.level == Level.verbose
            ? (path) => logger.detail('Excluded: $path')
            : null,
      );

      if (logger.level == Level.verbose) {
        logger
          ..detail('Config: ${result.configPath}')
          ..detail('Project root: ${result.projectRoot}');
      }

      formatGenRunSummary(result).forEach(logger.info);

      return ExitCode.success.code;
    } on BrickGenConfigNotFoundException catch (error) {
      logger.err(error.toString());
      return ExitCode.software.code;
    } on BrickGenConfigException catch (error) {
      logger.err(error.message);
      return ExitCode.software.code;
    } on GenerationException catch (error) {
      logger.err(error.message);
      return ExitCode.software.code;
    }
  }
}
