import 'dart:io';

import 'package:test/test.dart';

import '../prepare_package_release.dart';

void main() {
  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('clay_prepare_release_');
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('readPubspecNameAndVersion', () {
    test('reads name and version from pubspec.yaml', () {
      final pubspecFile = _writePubspec(
        directory: tempRoot,
        name: 'synthetic_pkg',
        version: '1.2.3-dev.4',
      );

      final result = readPubspecNameAndVersion(pubspecFile);

      expect(result.errorMessage, isNull);
      expect(result.name, 'synthetic_pkg');
      expect(result.version, '1.2.3-dev.4');
    });

    test('fails when name is missing', () {
      final pubspecFile = File('${tempRoot.path}/pubspec.yaml')
        ..writeAsStringSync('version: 0.1.0\n');

      final result = readPubspecNameAndVersion(pubspecFile);

      expect(result.name, isNull);
      expect(result.version, isNull);
      expect(result.errorMessage, contains('Could not read name'));
    });

    test('fails when version is missing', () {
      final pubspecFile = File('${tempRoot.path}/pubspec.yaml')
        ..writeAsStringSync('name: synthetic_pkg\n');

      final result = readPubspecNameAndVersion(pubspecFile);

      expect(result.name, isNull);
      expect(result.version, isNull);
      expect(result.errorMessage, contains('Could not read version'));
    });
  });

  group('resolveGitRoot', () {
    test('resolves git root for a package inside a repo', () {
      _initGitRepo(tempRoot);
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg');
      _writePackage(
        packageDir: packageDir,
        name: 'synthetic_pkg',
        version: '0.0.1-dev.1',
      );
      _gitCommitAll(tempRoot, message: 'init package');

      final result = resolveGitRoot(packageDir);

      expect(result.errorMessage, isNull);
      expect(
        Directory(result.gitRoot!.path).resolveSymbolicLinksSync(),
        Directory(tempRoot.absolute.path).resolveSymbolicLinksSync(),
      );
    });

    test('fails when cwd is outside a git work tree', () {
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg');
      _writePackage(
        packageDir: packageDir,
        name: 'synthetic_pkg',
        version: '0.0.1-dev.1',
      );

      final result = resolveGitRoot(packageDir);

      expect(result.gitRoot, isNull);
      expect(result.errorMessage, contains('Not a git repository'));
    });
  });

  group('resolvePackageContext', () {
    test('resolves a valid package directory inside a git repo', () {
      _initGitRepo(tempRoot);
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg');
      _writePackage(
        packageDir: packageDir,
        name: 'synthetic_pkg',
        version: '0.0.1-dev.1',
      );
      _gitCommitAll(tempRoot, message: 'init package');

      final result = resolvePackageContext(packageDir.path);

      expect(result.errorMessage, isNull);
      final context = result.context!;
      expect(context.name, 'synthetic_pkg');
      expect(context.version, '0.0.1-dev.1');
      expect(context.packageCwd.path, packageDir.absolute.path);
      expect(
        Directory(context.gitRoot.path).resolveSymbolicLinksSync(),
        Directory(tempRoot.absolute.path).resolveSymbolicLinksSync(),
      );
    });

    test('fails when package directory does not exist', () {
      final result = resolvePackageContext('${tempRoot.path}/missing');

      expect(result.context, isNull);
      expect(result.errorMessage, contains('does not exist'));
    });

    test('fails when pubspec.yaml is missing', () {
      _initGitRepo(tempRoot);
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg')
        ..createSync(recursive: true);
      File('${packageDir.path}/CHANGELOG.md')
          .writeAsStringSync('# Changelog\n');
      _gitCommitAll(tempRoot, message: 'init without pubspec');

      final result = resolvePackageContext(packageDir.path);

      expect(result.context, isNull);
      expect(result.errorMessage, contains('Missing pubspec.yaml'));
    });

    test('fails when CHANGELOG.md is missing', () {
      _initGitRepo(tempRoot);
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg');
      _writePubspec(
        directory: packageDir,
        name: 'synthetic_pkg',
        version: '0.0.1-dev.1',
      );
      _gitCommitAll(tempRoot, message: 'init without changelog');

      final result = resolvePackageContext(packageDir.path);

      expect(result.context, isNull);
      expect(result.errorMessage, contains('Missing CHANGELOG.md'));
    });

    test('fails when pubspec name is missing', () {
      _initGitRepo(tempRoot);
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg')
        ..createSync(recursive: true);
      File('${packageDir.path}/pubspec.yaml').writeAsStringSync(
        'version: 0.0.1-dev.1\n',
      );
      File('${packageDir.path}/CHANGELOG.md')
          .writeAsStringSync('# Changelog\n');
      _gitCommitAll(tempRoot, message: 'invalid pubspec');

      final result = resolvePackageContext(packageDir.path);

      expect(result.context, isNull);
      expect(result.errorMessage, contains('Could not read name'));
    });

    test('fails when pubspec version is missing', () {
      _initGitRepo(tempRoot);
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg')
        ..createSync(recursive: true);
      File('${packageDir.path}/pubspec.yaml').writeAsStringSync(
        'name: synthetic_pkg\n',
      );
      File('${packageDir.path}/CHANGELOG.md')
          .writeAsStringSync('# Changelog\n');
      _gitCommitAll(tempRoot, message: 'invalid pubspec');

      final result = resolvePackageContext(packageDir.path);

      expect(result.context, isNull);
      expect(result.errorMessage, contains('Could not read version'));
    });

    test('fails when package directory is not inside a git repo', () {
      final packageDir = Directory('${tempRoot.path}/packages/synthetic_pkg');
      _writePackage(
        packageDir: packageDir,
        name: 'synthetic_pkg',
        version: '0.0.1-dev.1',
      );

      final result = resolvePackageContext(packageDir.path);

      expect(result.context, isNull);
      expect(result.errorMessage, contains('Not a git repository'));
    });
  });

  group('validateTagFormat', () {
    test('accepts clay monorepo format', () {
      expect(validateTagFormat('{name}/{version}'), isNull);
    });

    test('accepts single-package format', () {
      expect(validateTagFormat('v{version}'), isNull);
    });

    test('rejects template without version placeholder', () {
      expect(
        validateTagFormat('{name}/release'),
        contains('{version} exactly once'),
      );
    });

    test('rejects template with multiple version placeholders', () {
      expect(
        validateTagFormat('v{version}-{version}'),
        contains('{version} exactly once'),
      );
    });

    test('rejects invalid git ref literal characters', () {
      expect(
        validateTagFormat('release?{version}'),
        contains('invalid git ref characters'),
      );
    });
  });

  group('renderTagFormat', () {
    test('renders clay monorepo tag', () {
      expect(
        renderTagFormat(
          format: '{name}/{version}',
          name: 'clay_core',
          version: '0.0.1-dev.2',
        ),
        'clay_core/0.0.1-dev.2',
      );
    });

    test('renders single-package tag', () {
      expect(
        renderTagFormat(
          format: 'v{version}',
          name: 'ignored',
          version: '1.0.0',
        ),
        'v1.0.0',
      );
    });
  });

  group('tagGlobForFormat', () {
    test('builds clay monorepo glob', () {
      expect(
        tagGlobForFormat(format: '{name}/{version}', name: 'clay_core'),
        'clay_core/*',
      );
    });

    test('builds single-package glob', () {
      expect(
        tagGlobForFormat(format: 'v{version}', name: 'ignored'),
        'v*',
      );
    });
  });
}

File _writePubspec({
  required Directory directory,
  required String name,
  required String version,
}) {
  directory.createSync(recursive: true);
  final pubspecFile = File('${directory.path}/pubspec.yaml')
    ..writeAsStringSync('''
name: $name
version: $version
''');
  return pubspecFile;
}

void _writePackage({
  required Directory packageDir,
  required String name,
  required String version,
}) {
  _writePubspec(directory: packageDir, name: name, version: version);
  File('${packageDir.path}/CHANGELOG.md').writeAsStringSync('# Changelog\n');
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
