import 'dart:io';

final pubspecNamePattern = RegExp(
  r'^name:\s+(\S+)\s*$',
  multiLine: true,
);
final pubspecVersionPattern = RegExp(
  r'^version:\s+(\S+)\s*$',
  multiLine: true,
);
final pubspecRepositoryPattern = RegExp(
  r'^repository:\s+(\S+)\s*$',
  multiLine: true,
);
final pubspecIssueTrackerPattern = RegExp(
  r'^issue_tracker:\s+(\S+)\s*$',
  multiLine: true,
);

/// Reads `name:` and `version:` from [pubspecFile].
///
/// Returns a structured error when either field is missing or empty.
({String? name, String? version, String? errorMessage})
    readPubspecNameAndVersion(
  File pubspecFile,
) {
  final contents = pubspecFile.readAsStringSync();

  final nameMatch = pubspecNamePattern.firstMatch(contents);
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

  final versionMatch = pubspecVersionPattern.firstMatch(contents);
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

/// Reads the `version:` field from [pubspecFile].
///
/// Returns a structured error when the version cannot be read.
({String? version, String? errorMessage}) readPubspecVersion(File pubspecFile) {
  final match = pubspecVersionPattern.firstMatch(
    pubspecFile.readAsStringSync(),
  );
  if (match == null) {
    return (
      version: null,
      errorMessage:
          'Could not read version from pubspec.yaml: ${pubspecFile.path}',
    );
  }

  final version = match.group(1)!;
  if (version.isEmpty) {
    return (
      version: null,
      errorMessage:
          'pubspec.yaml version must be a non-empty string: ${pubspecFile.path}',
    );
  }

  return (version: version, errorMessage: null);
}

/// Optional `repository:` and `issue_tracker:` values from [pubspecFile].
({String? repository, String? issueTracker}) readPubspecRepositoryFields(
  File pubspecFile,
) {
  final contents = pubspecFile.readAsStringSync();

  final repositoryMatch = pubspecRepositoryPattern.firstMatch(contents);
  final issueTrackerMatch = pubspecIssueTrackerPattern.firstMatch(contents);

  return (
    repository: repositoryMatch?.group(1),
    issueTracker: issueTrackerMatch?.group(1),
  );
}

/// Replaces only the `version:` line in [pubspecContents].
///
/// Returns a structured error when the version line is missing.
({String? contents, String? errorMessage}) updatePubspecVersionLine({
  required String pubspecContents,
  required String newVersion,
}) {
  final match = pubspecVersionPattern.firstMatch(pubspecContents);
  if (match == null) {
    return (
      contents: null,
      errorMessage: 'Could not find version line in pubspec.yaml.',
    );
  }

  return (
    contents: pubspecContents.replaceFirst(
      match.group(0)!,
      'version: $newVersion',
    ),
    errorMessage: null,
  );
}
