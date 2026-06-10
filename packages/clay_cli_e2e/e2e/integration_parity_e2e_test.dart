import 'package:test/test.dart';

import 'helpers/compare_directory_trees.dart';
import 'helpers/integration_fixture.dart';
import 'helpers/run_clay.dart';

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
            final result = await runClay(
              ['gen', '--cwd', fixture.workingRoot.path],
              workingDirectory: fixture.workingRoot.path,
              e2ePackageRoot: fixture.packageRoot.path,
            );

            expect(result.exitCode, 0, reason: result.stderr);
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
            final result = await runClay(
              ['validate', '--cwd', fixture.workingRoot.path],
              workingDirectory: fixture.workingRoot.path,
              e2ePackageRoot: fixture.packageRoot.path,
            );

            expect(result.exitCode, 0, reason: result.stdout);
            expect(result.stderr, isEmpty);
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'lib/ref_app/widget.dart',
              '--template-only',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'lib/ref_models/task.dart',
              '--template-only',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'lib/main.dart',
              '--template-only',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'lib/ref_shared/util.dart',
              '--template-only',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'templates/model.html',
              '--template-only',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'lib/ref_cache/view.dart',
              '--template-only',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'lib/ref_cache/view.dart',
              '--vars',
              'use_riverpod=true',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
          final result = await runClay(
            [
              'preview',
              '--cwd',
              fixture.workingRoot.path,
              '--file',
              'lib/ref_cache/view.dart',
              '--vars',
              'use_riverpod=false',
            ],
            workingDirectory: fixture.workingRoot.path,
            e2ePackageRoot: fixture.packageRoot.path,
          );

          expect(result.exitCode, 0, reason: result.stderr);
          expect(
            result.stdout,
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
