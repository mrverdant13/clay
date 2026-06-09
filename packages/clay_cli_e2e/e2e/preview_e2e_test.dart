import 'package:test/test.dart';

import 'helpers/fixture_project.dart';
import 'helpers/run_clay.dart';

void main() {
  group('clay preview', () {
    late E2eFixtureProject project;

    setUp(() {
      project = E2eFixtureProject.withFiles(
        configJson: '''
{
  "reference": "reference",
  "target": "target",
  "replacements": [
    {
      "from": "Widget",
      "to": "{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}{{^use_riverpod}}StatelessWidget{{/use_riverpod}}"
    }
  ]
}
''',
        referenceFiles: {
          'widget.dart': '''
class App extends Widget {
  /*remove-start*/
  // scaffold
  /*remove-end*/
}
''',
        },
      );
    });

    tearDown(() => project.dispose());

    test(
      'writes template-only output to stdout',
      () async {
        final result = await runClay(
          [
            'preview',
            '--cwd',
            project.root.path,
            '--file',
            'widget.dart',
            '--template-only',
          ],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(
          result.stdout,
          allOf(
            contains('{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}'),
            contains('{{^use_riverpod}}StatelessWidget{{/use_riverpod}}'),
            isNot(contains('remove-start')),
            isNot(contains('scaffold')),
          ),
        );
      },
      tags: const ['e2e'],
    );

    test(
      'renders mustache variables when --vars is provided',
      () async {
        final result = await runClay(
          [
            'preview',
            '--cwd',
            project.root.path,
            '--file',
            'widget.dart',
            '--vars',
            'use_riverpod=true',
          ],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(result.stdout, contains('class App extends ConsumerWidget'));
        expect(result.stdout, isNot(contains('remove-start')));
        expect(result.stdout, isNot(contains('scaffold')));
      },
      tags: const ['e2e'],
    );

    test(
      'selects the stateless branch when use_riverpod is false',
      () async {
        final result = await runClay(
          [
            'preview',
            '--cwd',
            project.root.path,
            '--file',
            'widget.dart',
            '--vars',
            'use_riverpod=false',
          ],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, 0, reason: result.stderr);
        expect(result.stdout, contains('class App extends StatelessWidget'));
      },
      tags: const ['e2e'],
    );
  });
}
