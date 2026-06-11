import 'package:clay/config.dart';
import 'package:clay/validation.dart';
import 'package:clay_cli/src/commands/clay_command.dart';
import 'package:clay_cli/src/run/run_validate.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template clay_cli.validate_command}
/// Validates annotation markers in the reference project.
/// {@endtemplate}
class ValidateCommand extends ClayCommand {
  /// {@macro clay_cli.validate_command}
  ValidateCommand();

  /// The command name for `clay validate`.
  static const String commandName = 'validate';

  @override
  String get name => commandName;

  @override
  String get description =>
      'Validate annotation markers in the reference project.';

  @override
  Future<int> run() async {
    try {
      final result = await runValidate(
        configPath: configPath,
        cwd: cwd,
        referenceOverride: referenceOverride,
      );

      if (logger.level == Level.verbose) {
        logger
          ..detail('Config: ${result.configPath}')
          ..detail('Project root: ${result.projectRoot}')
          ..detail('Reference: ${result.referencePath}');
      }

      if (result.issues.isEmpty) {
        return ExitCode.success.code;
      }

      formatValidateIssues(result.issues).forEach(logger.err);
      return validationIssuesExitCode;
    } on ClayConfigNotFoundException catch (error) {
      logger.err(error.toString());
      return ExitCode.software.code;
    } on ClayConfigException catch (error) {
      logger.err(error.message);
      return ExitCode.software.code;
    } on ValidationException catch (error) {
      logger.err(error.message);
      return ExitCode.software.code;
    }
  }
}
