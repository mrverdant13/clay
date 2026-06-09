import 'package:test/test.dart';

import 'helpers/fixture_project.dart';
import 'helpers/run_clay.dart';

void main() {
  group('clay validate', () {
    late E2eFixtureProject project;

    setUp(() {
      project = E2eFixtureProject.create(
        referenceFiles: {
          'main.dart': 'void main() {}\n',
        },
      );
    });

    tearDown(() => project.dispose());

    test(
      'exits successfully when annotations are valid',
      () async {
        final result = await runClay(
          ['validate', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(result.stderr, isEmpty);
      },
      tags: const ['e2e'],
    );

    test(
      'reports issues to stderr and exits with code 1',
      () async {
        project.dispose();
        project = E2eFixtureProject.create(
          referenceFiles: {
            'broken.dart': '/*remove-start*/\n',
          },
        );

        final result = await runClay(
          ['validate', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 1, reason: result.stdout);
        expect(
          result.stderr,
          allOf(
            contains('broken.dart'),
            contains('Unmatched remove-start marker'),
          ),
        );
      },
      tags: const ['e2e'],
    );
  });
}
