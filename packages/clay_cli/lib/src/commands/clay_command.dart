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
        help: 'Overrides brick-gen.json → reference.',
      )
      ..addOption(
        targetOptionName,
        help: 'Overrides brick-gen.json → target.',
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

  /// Explicit `--config` path, or `null` when omitted.
  String? get configPath =>
      _parsedGlobalOption(ClayCommandRunner.configOptionName);

  /// Explicit `--cwd` path, or `null` when omitted.
  String? get cwd => _parsedGlobalOption(ClayCommandRunner.cwdOptionName);

  /// Explicit `--reference` override, or `null` when omitted.
  String? get referenceOverride => _parsedOption(referenceOptionName);

  /// Explicit `--target` override, or `null` when omitted.
  String? get targetOverride => _parsedOption(targetOptionName);

  String? _parsedGlobalOption(String name) {
    final results = globalResults;
    if (results == null || !results.wasParsed(name)) {
      return null;
    }
    return results.option(name);
  }

  String? _parsedOption(String name) {
    final results = argResults;
    if (results == null || !results.wasParsed(name)) {
      return null;
    }
    return results.option(name);
  }
}
