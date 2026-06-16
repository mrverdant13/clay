import 'package:clay_core/clay.dart' show clayCoreVersion;
import 'package:test/test.dart';

import 'helpers/fixture_project.dart';
import 'helpers/run_clay.dart';

void main() {
  group('environment.clay compatibility', () {
    late E2eFixtureProject project;

    setUp(() {
      project = E2eFixtureProject.withFiles(
        configYaml: '''
reference: reference
target: target
environment:
  clay: ^0.2.0
''',
        referenceFiles: {
          'main.dart': 'void main() {}\n',
        },
      );
    });

    tearDown(() => project.dispose());

    test(
      'clay gen fails with a version mismatch message',
      () async {
        final result = await runClay(
          ['gen', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, isNonZero, reason: result.stdout);
        expect(
          result.stderr,
          allOf(
            contains('The current clay version is $clayCoreVersion'),
            contains('This project requires clay version ^0.2.0'),
          ),
        );
      },
      tags: const ['e2e'],
    );

    test(
      'clay validate fails with a version mismatch message',
      () async {
        final result = await runClay(
          ['validate', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, isNonZero, reason: result.stdout);
        expect(
          result.stderr,
          allOf(
            contains('The current clay version is $clayCoreVersion'),
            contains('This project requires clay version ^0.2.0'),
          ),
        );
      },
      tags: const ['e2e'],
    );

    test(
      'clay preview fails with a version mismatch message',
      () async {
        final result = await runClay(
          [
            'preview',
            '--cwd',
            project.root.path,
            '--file',
            'main.dart',
          ],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, isNonZero, reason: result.stdout);
        expect(
          result.stderr,
          allOf(
            contains('The current clay version is $clayCoreVersion'),
            contains('This project requires clay version ^0.2.0'),
          ),
        );
      },
      tags: const ['e2e'],
    );
  });
}
