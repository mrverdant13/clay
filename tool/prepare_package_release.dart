import 'dart:io';

final _pubspecNamePattern = RegExp(
  r'^name:\s+(\S+)\s*$',
  multiLine: true,
);
final _pubspecVersionPattern = RegExp(
  r'^version:\s+(\S+)\s*$',
  multiLine: true,
);

/// Package metadata and paths resolved from `--cwd`.
class PackageContext {
  const PackageContext({
    required this.name,
    required this.version,
    required this.packageCwd,
    required this.gitRoot,
  });

  final String name;
  final String version;
  final Directory packageCwd;
  final Directory gitRoot;
}

/// Reads `name:` and `version:` from [pubspecFile].
///
/// Returns a structured error when either field is missing or empty.
({String? name, String? version, String? errorMessage})
    readPubspecNameAndVersion(
  File pubspecFile,
) {
  final contents = pubspecFile.readAsStringSync();

  final nameMatch = _pubspecNamePattern.firstMatch(contents);
  if (nameMatch == null) {
    return (
      name: null,
      version: null,
      errorMessage:
          'Could not read name from pubspec.yaml: ${pubspecFile.path}',
    );
  }

  final name = nameMatch.group(1)!;
  if (name.isEmpty) {
    return (
      name: null,
      version: null,
      errorMessage:
          'pubspec.yaml name must be a non-empty string: ${pubspecFile.path}',
    );
  }

  final versionMatch = _pubspecVersionPattern.firstMatch(contents);
  if (versionMatch == null) {
    return (
      name: null,
      version: null,
      errorMessage:
          'Could not read version from pubspec.yaml: ${pubspecFile.path}',
    );
  }

  final version = versionMatch.group(1)!;
  if (version.isEmpty) {
    return (
      name: null,
      version: null,
      errorMessage: 'pubspec.yaml version must be a non-empty string: '
          '${pubspecFile.path}',
    );
  }

  return (name: name, version: version, errorMessage: null);
}

/// Resolves the git repository root containing [cwd].
///
/// Uses `git -C <cwd> rev-parse --show-toplevel`.
({Directory? gitRoot, String? errorMessage}) resolveGitRoot(Directory cwd) {
  final result = Process.runSync(
    'git',
    ['-C', cwd.path, 'rev-parse', '--show-toplevel'],
  );
  if (result.exitCode != 0) {
    final stderrText = result.stderr.toString().trim();
    if (stderrText.isNotEmpty) {
      return (
        gitRoot: null,
        errorMessage: 'Not a git repository: ${cwd.path} ($stderrText)',
      );
    }
    return (gitRoot: null, errorMessage: 'Not a git repository: ${cwd.path}');
  }

  final rootPath = result.stdout.toString().trim();
  if (rootPath.isEmpty) {
    return (
      gitRoot: null,
      errorMessage: 'Could not resolve git repository root for: ${cwd.path}',
    );
  }

  return (gitRoot: Directory(rootPath), errorMessage: null);
}

/// Resolves and validates package context from [cwdPath].
///
/// [cwdPath] is normalized to an absolute directory. Validation covers the
/// package directory, `pubspec.yaml`, `CHANGELOG.md`, and git work-tree
/// membership.
({PackageContext? context, String? errorMessage}) resolvePackageContext(
  String cwdPath,
) {
  final packageCwd = Directory(cwdPath).absolute;
  if (!packageCwd.existsSync()) {
    return (
      context: null,
      errorMessage: 'Package directory does not exist: ${packageCwd.path}',
    );
  }
  if (!FileSystemEntity.isDirectorySync(packageCwd.path)) {
    return (
      context: null,
      errorMessage: 'Package path is not a directory: ${packageCwd.path}',
    );
  }

  final pubspecFile = File('${packageCwd.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    return (
      context: null,
      errorMessage: 'Missing pubspec.yaml: ${pubspecFile.path}',
    );
  }

  final pubspecFields = readPubspecNameAndVersion(pubspecFile);
  if (pubspecFields.errorMessage != null) {
    return (context: null, errorMessage: pubspecFields.errorMessage);
  }

  final changelogFile = File('${packageCwd.path}/CHANGELOG.md');
  if (!changelogFile.existsSync()) {
    return (
      context: null,
      errorMessage: 'Missing CHANGELOG.md: ${changelogFile.path}',
    );
  }

  final gitRootResult = resolveGitRoot(packageCwd);
  if (gitRootResult.errorMessage != null) {
    return (context: null, errorMessage: gitRootResult.errorMessage);
  }

  return (
    context: PackageContext(
      name: pubspecFields.name!,
      version: pubspecFields.version!,
      packageCwd: packageCwd,
      gitRoot: gitRootResult.gitRoot!,
    ),
    errorMessage: null,
  );
}
