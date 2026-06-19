import 'dart:io';

import 'package:test/test.dart';

import '../release_tag.dart';
import '../sync_package_version.dart';

void main() {
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('clay_release_tag_');
  });

  tearDown(() {
    if (repoRoot.existsSync()) {
      repoRoot.deleteSync(recursive: true);
    }
  });

  test('builds annotated tag commands from pubspec version', () {
    _writePubspec(
      repoRoot: repoRoot,
      packagePath: 'packages/clay_core',
      version: '0.0.1-dev.2',
    );

    final result = buildReleaseTagPlan(
      'clay_core',
      packageConfigs['clay_core']!,
      repoRoot,
    );

    expect(result.errorMessage, isNull);
    final plan = result.plan!;
    expect(plan.tagName, 'clay_core/0.0.1-dev.2');
    expect(plan.tagMessage, 'clay_core 0.0.1-dev.2');
    expect(
      plan.printCommands(),
      '''
git tag -a clay_core/0.0.1-dev.2 -m 'clay_core 0.0.1-dev.2'
git push origin clay_core/0.0.1-dev.2''',
    );
  });

  test('fails when pubspec.yaml is missing', () {
    final result = buildReleaseTagPlan(
      'clay_cli',
      packageConfigs['clay_cli']!,
      repoRoot,
    );

    expect(result.plan, isNull);
    expect(result.errorMessage, contains('Missing pubspec.yaml'));
  });

  test('shell-quotes tag messages that need escaping', () {
    expect(
      formatShellCommand(['git', 'tag', '-a', 'clay_core/1.0.0', '-m', 'a b']),
      "git tag -a clay_core/1.0.0 -m 'a b'",
    );
  });

  group('verifyTagAtHead', () {
    test('accepts an annotated tag on HEAD', () {
      expect(
        verifyTagAtHead(
          tagName: 'clay_core/0.0.1-dev.2',
          headCommit: 'abc123',
          tagCommit: 'abc123',
          tagObjectType: 'tag',
        ),
        isNull,
      );
    });

    test('rejects a lightweight tag object type', () {
      expect(
        verifyTagAtHead(
          tagName: 'clay_core/0.0.1-dev.2',
          headCommit: 'abc123',
          tagCommit: 'abc123',
          tagObjectType: 'commit',
        ),
        'Release tag clay_core/0.0.1-dev.2 exists but is not annotated.',
      );
    });

    test('rejects a tag that points at a different commit', () {
      expect(
        verifyTagAtHead(
          tagName: 'clay_core/0.0.1-dev.2',
          headCommit: 'abc123',
          tagCommit: 'def456',
          tagObjectType: 'tag',
        ),
        'Release tag clay_core/0.0.1-dev.2 points at def456 but HEAD is abc123.',
      );
    });
  });

  group('verifyReleaseTagPlan', () {
    test('passes when annotated tag is on HEAD', () {
      _initGitRepo(repoRoot);
      _writePubspec(
        repoRoot: repoRoot,
        packagePath: 'packages/clay_core',
        version: '0.0.1-dev.2',
      );
      _gitCommitAll(repoRoot, message: 'release prep');
      _gitTagAnnotated(
        repoRoot,
        tagName: 'clay_core/0.0.1-dev.2',
        message: 'clay_core 0.0.1-dev.2',
      );

      final plan = buildReleaseTagPlan(
        'clay_core',
        packageConfigs['clay_core']!,
        repoRoot,
      ).plan!;

      expect(verifyReleaseTagPlan(plan, repoRoot), isNull);
    });

    test('fails when tag is missing', () {
      _initGitRepo(repoRoot);
      _writePubspec(
        repoRoot: repoRoot,
        packagePath: 'packages/clay_core',
        version: '0.0.1-dev.2',
      );
      _gitCommitAll(repoRoot, message: 'release prep');

      final plan = buildReleaseTagPlan(
        'clay_core',
        packageConfigs['clay_core']!,
        repoRoot,
      ).plan!;

      expect(
        verifyReleaseTagPlan(plan, repoRoot),
        'Release tag clay_core/0.0.1-dev.2 is missing on this checkout.',
      );
    });

    test('fails when tag is lightweight', () {
      _initGitRepo(repoRoot);
      _writePubspec(
        repoRoot: repoRoot,
        packagePath: 'packages/clay_core',
        version: '0.0.1-dev.2',
      );
      _gitCommitAll(repoRoot, message: 'release prep');
      _runGit(repoRoot, ['tag', 'clay_core/0.0.1-dev.2']);

      final plan = buildReleaseTagPlan(
        'clay_core',
        packageConfigs['clay_core']!,
        repoRoot,
      ).plan!;

      expect(
        verifyReleaseTagPlan(plan, repoRoot),
        'Release tag clay_core/0.0.1-dev.2 exists but is not annotated.',
      );
    });

    test('fails when tag points at a different commit', () {
      _initGitRepo(repoRoot);
      _writePubspec(
        repoRoot: repoRoot,
        packagePath: 'packages/clay_core',
        version: '0.0.1-dev.2',
      );
      _gitCommitAll(repoRoot, message: 'release prep');
      _gitTagAnnotated(
        repoRoot,
        tagName: 'clay_core/0.0.1-dev.2',
        message: 'clay_core 0.0.1-dev.2',
      );
      File('${repoRoot.path}/follow-up.txt').writeAsStringSync('noop');
      _gitCommitAll(repoRoot, message: 'follow-up');

      final plan = buildReleaseTagPlan(
        'clay_core',
        packageConfigs['clay_core']!,
        repoRoot,
      ).plan!;

      expect(
        verifyReleaseTagPlan(plan, repoRoot),
        startsWith('Release tag clay_core/0.0.1-dev.2 points at'),
      );
    });
  });
}

void _writePubspec({
  required Directory repoRoot,
  required String packagePath,
  required String version,
}) {
  final packageDir = Directory('${repoRoot.path}/$packagePath')
    ..createSync(recursive: true);
  File('${packageDir.path}/pubspec.yaml').writeAsStringSync('''
name: example
version: $version
''');
}

void _initGitRepo(Directory repoRoot) {
  _runGit(repoRoot, ['init']);
  _runGit(repoRoot, ['config', 'user.email', 'test@example.com']);
  _runGit(repoRoot, ['config', 'user.name', 'Test User']);
}

void _gitCommitAll(Directory repoRoot, {required String message}) {
  _runGit(repoRoot, ['add', '-A']);
  _runGit(repoRoot, ['commit', '-m', message]);
}

void _gitTagAnnotated(
  Directory repoRoot, {
  required String tagName,
  required String message,
}) {
  _runGit(repoRoot, ['tag', '-a', tagName, '-m', message]);
}

ProcessResult _runGit(Directory repoRoot, List<String> arguments) {
  final result = Process.runSync(
    'git',
    arguments,
    workingDirectory: repoRoot.path,
  );
  expect(
    result.exitCode,
    0,
    reason: 'git ${arguments.join(' ')} failed: ${result.stderr}',
  );
  return result;
}
