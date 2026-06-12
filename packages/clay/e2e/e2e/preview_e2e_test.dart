import 'package:test/test.dart';

import 'helpers/clay_api.dart';
import 'helpers/clay_project.dart';

void main() {
  group('clay previewReferenceFile', () {
    late ClayProject project;

    setUp(() {
      project = ClayProject.withFiles(
        configYaml: '''
reference: reference
target: target
replacements:
  - from: Widget
    to: "{{#use_riverpod}}ConsumerWidget{{/use_riverpod}}{{^use_riverpod}}StatelessWidget{{/use_riverpod}}"
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
      'returns template-only output',
      () async {
        final content = await runClayPreview(
          cwd: project.root.path,
          filePath: 'widget.dart',
          templateOnly: true,
        );

        expect(
          content,
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
      'renders mustache variables when vars are provided',
      () async {
        final content = await runClayPreview(
          cwd: project.root.path,
          filePath: 'widget.dart',
          templateOnly: false,
          vars: const {'use_riverpod': true},
        );

        expect(content, contains('class App extends ConsumerWidget'));
        expect(content, isNot(contains('remove-start')));
        expect(content, isNot(contains('scaffold')));
      },
      tags: const ['e2e'],
    );

    test(
      'selects the stateless branch when use_riverpod is false',
      () async {
        final content = await runClayPreview(
          cwd: project.root.path,
          filePath: 'widget.dart',
          templateOnly: false,
          vars: const {'use_riverpod': false},
        );

        expect(content, contains('class App extends StatelessWidget'));
      },
      tags: const ['e2e'],
    );
  });
}
