import 'dart:io';

import 'package:path/path.dart' as p;

/// Outcome of invoking the `clay` CLI as a child process.
class ClayProcessResult {
  /// Creates a [ClayProcessResult].
  const ClayProcessResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// Process exit code.
  final int exitCode;

  /// Captured stdout.
  final String stdout;

  /// Captured stderr.
  final String stderr;
}

/// Absolute path to `packages/clay_cli/bin/clay.dart` from the e2e package.
String clayCliScriptPath({String? e2ePackageRoot}) {
  final root = e2ePackageRoot ?? Directory.current.path;
  return p.normalize(
    p.join(root, '..', 'bin', 'clay.dart'),
  );
}

/// Runs `dart run <clay.dart> …` from [workingDirectory].
Future<ClayProcessResult> runClay(
  List<String> args, {
  required String workingDirectory,
  String? e2ePackageRoot,
}) async {
  final scriptPath = clayCliScriptPath(e2ePackageRoot: e2ePackageRoot);
  final result = await Process.run(
    Platform.resolvedExecutable,
    ['run', scriptPath, ...args],
    workingDirectory: workingDirectory,
  );

  return ClayProcessResult(
    exitCode: result.exitCode,
    stdout: result.stdout.toString(),
    stderr: result.stderr.toString(),
  );
}
