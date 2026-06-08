import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:clay_cli/src/commands/clay_command.dart';
import 'package:clay_cli/src/features/config/brick_gen_config_exception.dart';
import 'package:clay_cli/src/features/preview/parse_preview_vars.dart';
import 'package:clay_cli/src/features/preview/preview_exception.dart';
import 'package:clay_cli/src/features/preview/run_preview.dart';
import 'package:mason_logger/mason_logger.dart';

/// {@template clay_cli.preview_command}
/// Previews a single transformed reference file on stdout.
/// {@endtemplate}
class PreviewCommand extends ClayCommand {
  /// {@macro clay_cli.preview_command}
  PreviewCommand() {
    argParser
      ..addOption(
        fileOptionName,
        help: 'Path to a file under the reference directory.',
      )
      ..addFlag(
        templateOnlyOptionName,
        help: 'Apply config and annotations only; leave Mustache tags intact.',
      )
      ..addOption(
        varsOptionName,
        help: 'Comma-separated Mason variables for full preview rendering.',
      );
  }

  /// The command name for `clay preview`.
  static const String commandName = 'preview';

  /// Option name for `--file`.
  static const fileOptionName = 'file';

  /// Option name for `--template-only`.
  static const templateOnlyOptionName = 'template-only';

  /// Option name for `--vars`.
  static const varsOptionName = 'vars';

  @override
  String get name => commandName;

  @override
  String get description =>
      'Transform a single reference file and write the result to stdout.';

  @override
  Future<int> run() async {
    final filePath = argResults?.option(fileOptionName);
    if (filePath == null || filePath.isEmpty) {
      throw UsageException('Missing required --file.', usage);
    }

    try {
      final templateOnly =
          argResults?[templateOnlyOptionName] == true;
      final vars = parsePreviewVars(argResults?.option(varsOptionName));

      final result = await runPreview(
        filePath: filePath,
        templateOnly: templateOnly,
        vars: vars,
        configPath: configPath,
        cwd: cwd,
        referenceOverride: referenceOverride,
        targetOverride: targetOverride,
      );

      if (logger.level == Level.verbose) {
        logger
          ..detail('Config: ${result.configPath}')
          ..detail('Project root: ${result.projectRoot}')
          ..detail('Reference: ${result.referencePath}')
          ..detail('Target: ${result.targetPath}')
          ..detail('File: ${result.filePath}');
      }

      stdout.write(result.content);
      return ExitCode.success.code;
    } on FormatException catch (error) {
      logger.err(error.message);
      return ExitCode.usage.code;
    } on BrickGenConfigNotFoundException catch (error) {
      logger.err(error.toString());
      return ExitCode.software.code;
    } on BrickGenConfigException catch (error) {
      logger.err(error.message);
      return ExitCode.software.code;
    } on PreviewException catch (error) {
      logger.err(error.message);
      return ExitCode.software.code;
    }
  }
}
