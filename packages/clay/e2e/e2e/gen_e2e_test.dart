import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/clay_api.dart';
import 'helpers/clay_project.dart';

void main() {
  group('clay generateTemplate', () {
    late ClayProject project;

    setUp(() {
      project = ClayProject.withFiles(
        referenceFiles: {
          'main.dart': 'void main() {}\n',
          'lib/widget.dart': 'class Widget {}\n',
        },
      );
    });

    tearDown(() => project.dispose());

    test(
      'generates the target tree',
      () async {
        await runClayGenerate(cwd: project.root.path);

        expect(
          File(p.join(project.targetDir.path, 'main.dart')).readAsStringSync(),
          'void main() {}\n',
        );
        expect(
          File(p.join(project.targetDir.path, 'lib', 'widget.dart'))
              .readAsStringSync(),
          'class Widget {}\n',
        );
        expect(countTargetFiles(project.targetDir.path), 2);
      },
      tags: const ['e2e'],
    );

    test(
      'excludes files matched by ignore patterns',
      () async {
        project.dispose();
        project = ClayProject.withFiles(
          configYaml: '''
reference: reference
target: target
ignore:
  - build/
''',
          referenceFiles: {
            'main.dart': 'main\n',
            'build/output.txt': 'ignored\n',
          },
        );

        await runClayGenerate(cwd: project.root.path);

        expect(countTargetFiles(project.targetDir.path), 1);
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
