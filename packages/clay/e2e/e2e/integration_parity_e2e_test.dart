import 'package:test/test.dart';

import 'helpers/clay_api.dart';
import 'helpers/compare_directory_trees.dart';
import 'helpers/integration_fixture.dart';

void main() {
  const scopes = [
    'common',
    'entities',
    'dart_package',
    'app',
    'storage',
    'cache',
  ];

  group('integration parity fixtures', () {
    for (final scope in scopes) {
      group(scope, () {
        late IntegrationFixture fixture;

        setUp(() => fixture = IntegrationFixture.loadForTest(scope));

        test(
          'gen output matches golden tree',
          () async {
            await runClayGenerate(cwd: fixture.workingRoot.path);

            expectDirectoryTreesMatch(
              expected: fixture.expectedDir,
              actual: fixture.targetDir,
            );
          },
          tags: const ['e2e'],
        );

        test(
          'validate reports no annotation issues',
          () async {
            final issues = await runClayValidate(cwd: fixture.workingRoot.path);

            expect(issues, isEmpty);
          },
          tags: const ['e2e'],
        );
      });
    }

    group('preview', () {
      test(
        'app widget template output',
        () async {
          final fixture = IntegrationFixture.loadForTest('app');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'lib/ref_app/widget.dart',
            templateOnly: true,
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'widget.template.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );

      test(
        'entities task template output',
        () async {
          final fixture = IntegrationFixture.loadForTest('entities');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'lib/ref_models/task.dart',
            templateOnly: true,
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'task.template.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );

      test(
        'dart package main template output',
        () async {
          final fixture = IntegrationFixture.loadForTest('dart_package');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'lib/main.dart',
            templateOnly: true,
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'main.template.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );

      test(
        'common util template output',
        () async {
          final fixture = IntegrationFixture.loadForTest('common');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'lib/ref_shared/util.dart',
            templateOnly: true,
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'util.template.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );

      test(
        'storage html template output',
        () async {
          final fixture = IntegrationFixture.loadForTest('storage');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'templates/model.html',
            templateOnly: true,
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'model.template.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );

      test(
        'cache template output',
        () async {
          final fixture = IntegrationFixture.loadForTest('cache');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'lib/ref_cache/view.dart',
            templateOnly: true,
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'view.template.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );

      test(
        'cache rendered output with riverpod',
        () async {
          final fixture = IntegrationFixture.loadForTest('cache');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'lib/ref_cache/view.dart',
            templateOnly: false,
            vars: const {'use_riverpod': true},
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'view.riverpod.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );

      test(
        'cache rendered output without riverpod',
        () async {
          final fixture = IntegrationFixture.loadForTest('cache');
          final content = await runClayPreview(
            cwd: fixture.workingRoot.path,
            filePath: 'lib/ref_cache/view.dart',
            templateOnly: false,
            vars: const {'use_riverpod': false},
          );

          expect(
            content,
            readPreviewExpectation(
              fixtureRoot: fixture.root,
              fileName: 'view.stateless.txt',
            ),
          );
        },
        tags: const ['e2e'],
      );
    });
  });
}
