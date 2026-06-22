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
({String? name, String? version, String? errorMessage}) readPubspecNameAndVersion(
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
      errorMessage:
          'pubspec.yaml version must be a non-empty string: ${pubspecFile.path}',
    );
  }

  return (name: name, version: version, errorMessage: null);
}
