import 'dart:io';

import 'package:pub_semver/pub_semver.dart';

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

const _versionPlaceholder = '{version}';
const _namePlaceholder = '{name}';

/// Semver-shaped segment captured from a tag via [parseVersionFromTag].
const _semverCapturePattern =
    r'([0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)?(?:\+[0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)?)';

/// Characters that are invalid in git ref/tag literal segments.
final _invalidGitRefLiteralPattern = RegExp(
  r'[\x00-\x1f\x7f ~^:?*[\]\\]|@{|\.\.',
);

/// Validates [format] for use as `--tag-format`.
///
/// The template must contain `{version}` exactly once and literal characters
/// must be valid git ref/tag characters.
String? validateTagFormat(String format) {
  final versionCount = _versionPlaceholder.allMatches(format).length;
  if (versionCount == 0) {
    return 'Tag format must contain {version} exactly once: $format';
  }
  if (versionCount > 1) {
    return 'Tag format must contain {version} exactly once: $format';
  }

  final literalOnly = format
      .replaceAll(_namePlaceholder, '')
      .replaceAll(_versionPlaceholder, '');
  if (_invalidGitRefLiteralPattern.hasMatch(literalOnly)) {
    return 'Tag format contains invalid git ref characters: $format';
  }
  if (literalOnly.endsWith('.')) {
    return 'Tag format literal segment cannot end with ".": $format';
  }

  return null;
}

/// Substitutes `{name}` and `{version}` into [format].
String renderTagFormat({
  required String format,
  required String name,
  required String version,
}) {
  return format
      .replaceAll(_namePlaceholder, name)
      .replaceAll(_versionPlaceholder, version);
}

/// Builds a `git tag -l` glob from [format] with `{version}` replaced by `*`.
String tagGlobForFormat({
  required String format,
  required String name,
}) {
  return format
      .replaceAll(_namePlaceholder, name)
      .replaceAll(_versionPlaceholder, '*');
}

/// Parses the semver from [tag] using [format] and [name].
///
/// Returns `null` when [tag] does not match the full template.
Version? parseVersionFromTag({
  required String tag,
  required String format,
  required String name,
}) {
  final pattern = _tagFormatToRegExp(format: format, name: name);
  final match = pattern.firstMatch(tag);
  if (match == null) {
    return null;
  }

  final versionText = match.group(1);
  if (versionText == null || versionText.isEmpty) {
    return null;
  }

  try {
    return Version.parse(versionText);
  } on FormatException {
    return null;
  }
}

/// Lists release tags for [tagFormat] and returns the one with the highest
/// semver.
///
/// Non-matching tags and tags with unparseable versions are ignored.
({String? tag, Version? version, String? errorMessage}) resolveLatestTag({
  required Directory gitRoot,
  required String tagFormat,
  required String packageName,
}) {
  final formatError = validateTagFormat(tagFormat);
  if (formatError != null) {
    return (tag: null, version: null, errorMessage: formatError);
  }

  final glob = tagGlobForFormat(format: tagFormat, name: packageName);
  final result = Process.runSync(
    'git',
    ['-C', gitRoot.path, 'tag', '-l', glob],
  );
  if (result.exitCode != 0) {
    final stderrText = result.stderr.toString().trim();
    return (
      tag: null,
      version: null,
      errorMessage: stderrText.isEmpty
          ? 'Failed to list git tags matching "$glob".'
          : 'Failed to list git tags matching "$glob": $stderrText',
    );
  }

  String? latestTag;
  Version? latestVersion;

  for (final rawLine in result.stdout.toString().split('\n')) {
    final tag = rawLine.trim();
    if (tag.isEmpty) {
      continue;
    }

    final parsed = parseVersionFromTag(
      tag: tag,
      format: tagFormat,
      name: packageName,
    );
    if (parsed == null) {
      continue;
    }

    if (latestVersion == null || parsed > latestVersion) {
      latestTag = tag;
      latestVersion = parsed;
    }
  }

  return (tag: latestTag, version: latestVersion, errorMessage: null);
}

RegExp _tagFormatToRegExp({
  required String format,
  required String name,
}) {
  final buffer = StringBuffer('^');
  var index = 0;
  while (index < format.length) {
    if (format.startsWith(_namePlaceholder, index)) {
      buffer.write(RegExp.escape(name));
      index += _namePlaceholder.length;
      continue;
    }
    if (format.startsWith(_versionPlaceholder, index)) {
      buffer.write(_semverCapturePattern);
      index += _versionPlaceholder.length;
      continue;
    }
    buffer.write(RegExp.escape(format[index]));
    index++;
  }
  buffer.write(r'$');
  return RegExp(buffer.toString());
}

/// Conventional commit types recognized by the prepare release tool.
const supportedConventionalCommitTypes = {
  'build',
  'chore',
  'ci',
  'docs',
  'feat',
  'fix',
  'refactor',
  'test',
};

final _conventionalCommitSubjectPattern = RegExp(
  r'^([a-zA-Z]+)(?:\(([^)]*)\))?(!)?: (.+)$',
);

/// A conventional commit parsed from a git subject line.
class ConventionalCommit {
  const ConventionalCommit({
    required this.type,
    required this.scopes,
    required this.description,
    required this.subject,
    required this.isBreakingChange,
  });

  final String type;
  final List<String> scopes;
  final String description;
  final String subject;
  final bool isBreakingChange;
}

/// Parses [subject] into a [ConventionalCommit].
///
/// Returns `null` when [subject] is not a conventional commit header.
ConventionalCommit? parseConventionalCommitSubject(String subject) {
  final trimmed = subject.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  final match = _conventionalCommitSubjectPattern.firstMatch(trimmed);
  if (match == null) {
    return null;
  }

  final type = match.group(1)!.toLowerCase();
  final scopesRaw = match.group(2);
  final isBreakingChange = match.group(3) == '!';
  final description = match.group(4)!;
  if (description.isEmpty) {
    return null;
  }

  final scopes = scopesRaw == null || scopesRaw.isEmpty
      ? const <String>[]
      : scopesRaw
          .split(',')
          .map((scope) => scope.trim())
          .where((scope) => scope.isNotEmpty)
          .toList(growable: false);

  return ConventionalCommit(
    type: type,
    scopes: scopes,
    description: description,
    subject: trimmed,
    isBreakingChange: isBreakingChange,
  );
}

/// Parses a comma-separated `--commit-types` value.
///
/// Types are normalized to lowercase. Unknown type names produce
/// [errorMessage].
({Set<String>? types, String? errorMessage}) parseCommitTypes(String input) {
  final segments = input
      .split(',')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty);
  if (segments.isEmpty) {
    return (
      types: null,
      errorMessage: 'Commit types list must not be empty.',
    );
  }

  final normalized = <String>{};
  final unknown = <String>[];

  for (final segment in segments) {
    final type = segment.toLowerCase();
    if (!supportedConventionalCommitTypes.contains(type)) {
      unknown.add(segment);
      continue;
    }
    normalized.add(type);
  }

  if (unknown.isNotEmpty) {
    return (
      types: null,
      errorMessage: 'Unknown commit type(s): ${unknown.join(', ')}',
    );
  }

  return (types: normalized, errorMessage: null);
}

/// Returns commits from [subjects] scoped to [packageName] with an allowed
/// [allowedTypes] entry.
///
/// Unscoped commits, wrong scopes, non-conventional subjects, and disallowed
/// types are excluded.
List<ConventionalCommit> filterConventionalCommits({
  required Iterable<String> subjects,
  required String packageName,
  required Set<String> allowedTypes,
}) {
  final filtered = <ConventionalCommit>[];

  for (final subject in subjects) {
    final commit = parseConventionalCommitSubject(subject);
    if (commit == null) {
      continue;
    }
    if (commit.scopes.isEmpty || !commit.scopes.contains(packageName)) {
      continue;
    }
    if (!allowedTypes.contains(commit.type)) {
      continue;
    }
    filtered.add(commit);
  }

  return filtered;
}
