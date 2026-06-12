import 'dart:io';

import 'package:clay_cli/src/version.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  test(
    'clay --version prints package version',
    () async {
      final dartExecutable = Platform.resolvedExecutable;
      final clayCliRelativeScriptPath = p.joinAll([
        '..',
        'clay_cli',
        'bin',
        'clay.dart',
      ]);

      final result = await Process.run(
        dartExecutable,
        ['run', clayCliRelativeScriptPath, '--version'],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(result.stdout.toString(), contains(packageVersion));
    },
    tags: const ['e2e'],
  );
}
