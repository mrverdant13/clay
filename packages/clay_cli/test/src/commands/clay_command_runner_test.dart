import 'package:clay_cli/src/commands/clay_command_runner.dart';
import 'package:clay_cli/src/version.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

class _RecordingLogger extends Logger {
  _RecordingLogger() : super(level: Level.quiet);

  final messages = <String>[];

  @override
  void info(String? message, {LogStyle? style}) {
    if (message != null) {
      messages.add(message);
    }
  }
}

void main() {
  group('ClayCommandRunner', () {
    test('--version prints package version and exits successfully', () async {
      final logger = _RecordingLogger();
      final runner = ClayCommandRunner(logger: logger);

      final exitCode = await runner.run(const ['--version']);

      expect(exitCode, ExitCode.success.code);
      expect(logger.messages, contains(packageVersion));
    });

    test('missing command exits with usage code', () async {
      final runner = ClayCommandRunner(logger: Logger(level: Level.quiet));

      final exitCode = await runner.run(const <String>[]);

      expect(exitCode, ExitCode.usage.code);
    });
  });
}
