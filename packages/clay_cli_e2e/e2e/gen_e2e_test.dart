import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/fixture_project.dart';
import 'helpers/run_clay.dart';

void main() {
  group('clay gen', () {
    late E2eFixtureProject project;

    setUp(() {
      project = E2eFixtureProject.withFiles(
        referenceFiles: {
          'main.dart': 'void main() {}\n',
          'lib/widget.dart': 'class Widget {}\n',
        },
      );
    });

    tearDown(() => project.dispose());

    test(
      'generates the target tree and prints a summary',
      () async {
        final result = await runClay(
          ['gen', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(
          result.stdout,
          allOf(
            contains('Reference:'),
            contains(p.normalize(p.join(project.root.path, 'reference'))),
            contains('Target:'),
            contains(p.normalize(p.join(project.root.path, 'target'))),
            contains('Files: 2'),
          ),
        );
        expect(
          File(p.join(project.targetDir.path, 'main.dart')).readAsStringSync(),
          'void main() {}\n',
        );
        expect(
          File(p.join(project.targetDir.path, 'lib', 'widget.dart'))
              .readAsStringSync(),
          'class Widget {}\n',
        );
      },
      tags: const ['e2e'],
    );

    test(
      'runs as the default command when no subcommand is given',
      () async {
        final result = await runClay(
          ['--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(result.stdout, contains('Files: 2'));
      },
      tags: const ['e2e'],
    );

    test(
      'excludes files matched by ignore patterns',
      () async {
        project.dispose();
        project = E2eFixtureProject.withFiles(
          configJson: '''
{
  "reference": "reference",
  "target": "target",
  "ignore": ["build/"]
}
''',
          referenceFiles: {
            'main.dart': 'main\n',
            'build/output.txt': 'ignored\n',
          },
        );

        final result = await runClay(
          ['gen', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(result.stdout, contains('Files: 1'));
        expect(
          File(p.join(project.targetDir.path, 'build', 'output.txt'))
              .existsSync(),
          isFalse,
        );
      },
      tags: const ['e2e'],
    );
  });
}
