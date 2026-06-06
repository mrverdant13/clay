import 'package:clay_cli/src/commands/clay_command_runner.dart';
import 'package:mason_logger/mason_logger.dart';

/// Runs the Clay CLI with the given [args].
Future<int> clay({
  required List<String> args,
  required Logger logger,
}) {
  final runner = ClayCommandRunner(
    logger: logger,
  );
  return runner.run(args);
}
