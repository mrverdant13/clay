import 'dart:io';

import 'package:clay_core/clay.dart';
import 'package:io/io.dart';
import 'package:test/test.dart';

import 'helpers/fixture_project.dart';
import 'helpers/run_clay.dart';

void main() {
  group('clay compat', () {
    test(
      'exits successfully with empty stderr when environment.clay is omitted',
      () async {
        final project = E2eFixtureProject.withFiles();
        addTearDown(project.dispose);

        final result = await runClay(
          ['compat', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.success.code, reason: result.stderr);
        expect(result.stderr, isEmpty);
        expect(result.stdout, isEmpty);
      },
      tags: const ['e2e'],
    );

    test(
      'exits successfully when environment.clay is any',
      () async {
        final project = E2eFixtureProject.withFiles(
          configYaml: '''
reference: reference
target: target
environment:
  clay: any
''',
        );
        addTearDown(project.dispose);

        final result = await runClay(
          ['compat', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.success.code, reason: result.stderr);
        expect(result.stderr, isEmpty);
      },
      tags: const ['e2e'],
    );

    test(
      'exits successfully when environment.clay allows the current version',
      () async {
        final project = E2eFixtureProject.withFiles(
          configYaml: '''
reference: reference
target: target
environment:
  clay: ^$clayCoreVersion
''',
        );
        addTearDown(project.dispose);

        final result = await runClay(
          ['compat', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.success.code, reason: result.stderr);
        expect(result.stderr, isEmpty);
      },
      tags: const ['e2e'],
    );

    test(
      'fails with a version mismatch message for ^0.2.0',
      () async {
        final project = E2eFixtureProject.withFiles(
          configYaml: '''
reference: reference
target: target
environment:
  clay: ^0.2.0
''',
        );
        addTearDown(project.dispose);

        final result = await runClay(
          ['compat', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.software.code, reason: result.stdout);
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
      'fails with a version mismatch message for ^99.0.0',
      () async {
        final project = E2eFixtureProject.withFiles(
          configYaml: '''
reference: reference
target: target
environment:
  clay: ^99.0.0
''',
        );
        addTearDown(project.dispose);

        final result = await runClay(
          ['compat', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.software.code, reason: result.stdout);
        expect(
          result.stderr,
          allOf(
            contains('The current clay version is $clayCoreVersion'),
            contains('This project requires clay version ^99.0.0'),
          ),
        );
      },
      tags: const ['e2e'],
    );

    test(
      'fails when clay.yaml is missing',
      () async {
        final project = E2eFixtureProject.withFiles();
        addTearDown(project.dispose);
        File('${project.root.path}/clay.yaml').deleteSync();

        final result = await runClay(
          ['compat', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.software.code, reason: result.stdout);
        expect(result.stderr, contains('clay.yaml'));
      },
      tags: const ['e2e'],
    );

    test(
      'fails when environment.clay is invalid',
      () async {
        final project = E2eFixtureProject.withFiles(
          configYaml: '''
reference: reference
target: target
environment:
  clay: not-a-version
''',
        );
        addTearDown(project.dispose);

        final result = await runClay(
          ['compat', '--cwd', project.root.path],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.software.code, reason: result.stdout);
        expect(result.stderr, contains('Invalid environment'));
      },
      tags: const ['e2e'],
    );

    test(
      'returns usage exit code for invalid flags',
      () async {
        final project = E2eFixtureProject.withFiles();
        addTearDown(project.dispose);

        final result = await runClay(
          ['compat', '--cwd', project.root.path, '--bogus'],
          workingDirectory: project.root.path,
        );

        expect(result.exitCode, ExitCode.usage.code, reason: result.stdout);
        expect(result.stderr, contains('Could not find'));
      },
      tags: const ['e2e'],
    );
  });
}
