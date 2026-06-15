import 'package:test/test.dart';

import 'helpers/clay_api.dart';
import 'helpers/clay_project.dart';

void main() {
  group('clay validateAnnotations', () {
    late ClayProject project;

    setUp(() {
      project = ClayProject.withFiles(
        referenceFiles: {
          'main.dart': 'void main() {}\n',
        },
      );
    });

    tearDown(() => project.dispose());

    test(
      'returns no issues when annotations are valid',
      () async {
        final issues = await runClayValidate(cwd: project.root.path);

        expect(issues, isEmpty);
      },
      tags: const ['e2e'],
    );

    test(
      'returns issues for unmatched remove markers',
      () async {
        project.dispose();
        project = ClayProject.withFiles(
          referenceFiles: {
            'broken.dart': '/*remove-start*/\n',
          },
        );

        final issues = await runClayValidate(cwd: project.root.path);

        expect(issues, isNotEmpty);
        expect(
          issues.map((issue) => issue.toString()).join('\n'),
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
