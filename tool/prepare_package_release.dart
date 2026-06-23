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
    this.body,
  });

  final String type;
  final List<String> scopes;
  final String description;
  final String subject;
  final bool isBreakingChange;
  final String? body;
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
/// Types are normalized to lowercase. Unknown type names produce error message.
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

const _devPrereleaseId = 'dev';

final _breakingChangeFooterPattern = RegExp(
  'BREAKING CHANGE:',
  caseSensitive: false,
);

/// Explicit semver bump segment for `--bump`.
enum ExplicitVersionBump {
  build,
  patch,
  minor,
  major,
}

/// Returns `true` when [version] uses the v1 `-dev.N` prerelease format.
bool isDevPrereleaseVersion(Version version) {
  if (version.preRelease.isEmpty) {
    return false;
  }
  if (version.preRelease.length != 2) {
    return false;
  }
  if (version.preRelease.first != _devPrereleaseId) {
    return false;
  }
  final buildPart = version.preRelease[1];
  final buildNumber =
      buildPart is int ? buildPart : int.tryParse(buildPart as String);
  return buildNumber != null && buildNumber > 0;
}

/// Parses [versionText] and validates the v1 `-dev.N` prerelease format.
({Version? version, String? errorMessage}) parseDevPrereleaseVersionText(
  String versionText,
) {
  final trimmed = versionText.trim();
  if (trimmed.isEmpty) {
    return (version: null, errorMessage: 'Version must not be empty.');
  }

  try {
    final version = Version.parse(trimmed);
    if (!isDevPrereleaseVersion(version)) {
      return (
        version: null,
        errorMessage:
            'Version must use -dev.N prerelease format in v1: $trimmed',
      );
    }
    return (version: version, errorMessage: null);
  } on FormatException {
    return (version: null, errorMessage: 'Invalid semver version: $trimmed');
  }
}

/// Applies an explicit `--bump` override to [current].
Version applyExplicitVersionBump({
  required Version current,
  required ExplicitVersionBump bump,
}) {
  switch (bump) {
    case ExplicitVersionBump.build:
      final buildPart = current.preRelease[1];
      final buildNumber =
          buildPart is int ? buildPart : int.parse(buildPart as String);
      return Version(
        current.major,
        current.minor,
        current.patch,
        pre: '$_devPrereleaseId.${buildNumber + 1}',
      );
    case ExplicitVersionBump.patch:
      return Version(
        current.major,
        current.minor,
        current.patch + 1,
        pre: '$_devPrereleaseId.1',
      );
    case ExplicitVersionBump.minor:
      return Version(
        current.major,
        current.minor + 1,
        0,
        pre: '$_devPrereleaseId.1',
      );
    case ExplicitVersionBump.major:
      return Version(
        current.major + 1,
        0,
        0,
        pre: '$_devPrereleaseId.1',
      );
  }
}

/// Returns `true` when [commit] indicates a breaking change.
bool hasBreakingChange(ConventionalCommit commit) {
  if (commit.isBreakingChange) {
    return true;
  }
  final body = commit.body;
  if (body == null || body.isEmpty) {
    return false;
  }
  return _breakingChangeFooterPattern.hasMatch(body);
}

enum AutoBumpImpact {
  major,
  minor,
  patch,
  build,
}

/// Derives the highest semver impact from filtered [commits].
AutoBumpImpact determineAutoBumpImpact(List<ConventionalCommit> commits) {
  var hasBreakingFeat = false;
  var hasFeat = false;
  var hasFix = false;

  for (final commit in commits) {
    switch (commit.type) {
      case 'feat':
        if (hasBreakingChange(commit)) {
          hasBreakingFeat = true;
        } else {
          hasFeat = true;
        }
      case 'fix':
        hasFix = true;
      default:
        break;
    }
  }

  if (hasBreakingFeat) {
    return AutoBumpImpact.major;
  }
  if (hasFeat) {
    return AutoBumpImpact.minor;
  }
  if (hasFix) {
    return AutoBumpImpact.patch;
  }
  return AutoBumpImpact.build;
}

/// Applies auto bump rules from [commits] to [current].
Version applyAutoVersionBump({
  required Version current,
  required List<ConventionalCommit> commits,
}) {
  switch (determineAutoBumpImpact(commits)) {
    case AutoBumpImpact.major:
      return Version(
        current.major + 1,
        0,
        0,
        pre: '$_devPrereleaseId.1',
      );
    case AutoBumpImpact.minor:
      return Version(
        current.major,
        current.minor + 1,
        0,
        pre: '$_devPrereleaseId.1',
      );
    case AutoBumpImpact.patch:
      return Version(
        current.major,
        current.minor,
        current.patch + 1,
        pre: '$_devPrereleaseId.1',
      );
    case AutoBumpImpact.build:
      return applyExplicitVersionBump(
        current: current,
        bump: ExplicitVersionBump.build,
      );
  }
}

/// Computes the next `-dev.N` version from [currentVersion].
///
/// When [explicitBump] and [explicitVersionText] are both set, returns a
/// structured error. Auto mode requires at least one commit.
({Version? nextVersion, String? errorMessage}) computeNextVersion({
  required Version currentVersion,
  ExplicitVersionBump? explicitBump,
  String? explicitVersionText,
  List<ConventionalCommit> commits = const [],
}) {
  if (explicitBump != null && explicitVersionText != null) {
    return (
      nextVersion: null,
      errorMessage: '--bump and --version are mutually exclusive.',
    );
  }

  if (!isDevPrereleaseVersion(currentVersion)) {
    return (
      nextVersion: null,
      errorMessage: 'Current version must use -dev.N prerelease format in v1: '
          '$currentVersion',
    );
  }

  if (explicitVersionText != null) {
    final parsed = parseDevPrereleaseVersionText(explicitVersionText);
    if (parsed.errorMessage != null) {
      return (nextVersion: null, errorMessage: parsed.errorMessage);
    }
    return (nextVersion: parsed.version, errorMessage: null);
  }

  if (explicitBump != null) {
    return (
      nextVersion: applyExplicitVersionBump(
        current: currentVersion,
        bump: explicitBump,
      ),
      errorMessage: null,
    );
  }

  if (commits.isEmpty) {
    return (
      nextVersion: null,
      errorMessage: 'No conventional commits available for auto version bump.',
    );
  }

  return (
    nextVersion: applyAutoVersionBump(
      current: currentVersion,
      commits: commits,
    ),
    errorMessage: null,
  );
}

/// Maps a conventional commit type to its changelog label.
String changelogTypeLabel(String type) {
  return type.toUpperCase();
}

final _commitShaMarkdownLinkPattern = RegExp(
  r'\(\[([0-9a-f]{7,40})\]\([^)]+\)\)',
  caseSensitive: false,
);

/// Extracts a commit SHA markdown link from [body] when present.
String? extractCommitShaMarkdownLink(String? body) {
  if (body == null || body.isEmpty) {
    return null;
  }

  final match = _commitShaMarkdownLinkPattern.firstMatch(body);
  if (match == null) {
    return null;
  }

  return match.group(0);
}

/// Formats a single changelog bullet for [commit].
///
/// Preserves issue/PR links present in the subject description. When commit
/// body contains a commit SHA markdown link, it is appended after the
/// description.
String formatChangelogBullet(ConventionalCommit commit) {
  final label = changelogTypeLabel(commit.type);
  final description = commit.description.trim();
  final buffer = StringBuffer(' - **$label**: $description');

  final shaLink = extractCommitShaMarkdownLink(commit.body);
  if (shaLink != null && !description.contains(shaLink)) {
    if (!description.endsWith('.')) {
      buffer.write('.');
    }
    buffer.write(' $shaLink');
  } else if (!description.endsWith('.')) {
    buffer.write('.');
  }

  return buffer.toString();
}

/// Builds a `## <version>` changelog section from [commits].
///
/// Returns a structured error when [commits] is empty.
({String? section, String? errorMessage}) buildChangelogSection({
  required String version,
  required List<ConventionalCommit> commits,
  String? latestTag,
  String? packageName,
  Set<String>? allowedTypes,
}) {
  if (commits.isEmpty) {
    final tagText = latestTag ?? '(none)';
    final nameText = packageName ?? '(unknown)';
    final typesText = allowedTypes == null || allowedTypes.isEmpty
        ? '(none)'
        : allowedTypes.join(', ');
    return (
      section: null,
      errorMessage: 'No commits matching scope and type filters since tag '
          '$tagText for package $nameText with allowed types: $typesText.',
    );
  }

  final lines = <String>[
    '## $version',
    '',
    for (final commit in commits) formatChangelogBullet(commit),
  ];

  return (section: lines.join('\n'), errorMessage: null);
}

/// Prepends [section] to [existingChangelog], preserving existing content.
String prependChangelogSection({
  required String existingChangelog,
  required String section,
}) {
  final trimmedExisting = existingChangelog.trimRight();
  if (trimmedExisting.isEmpty) {
    return '$section\n';
  }

  return '$section\n\n$trimmedExisting\n';
}

/// Builds a release changelog by prepending a new section for [version].
({String? changelog, String? section, String? errorMessage})
    buildReleaseChangelog({
  required String version,
  required String existingChangelog,
  required List<ConventionalCommit> commits,
  String? latestTag,
  String? packageName,
  Set<String>? allowedTypes,
}) {
  final sectionResult = buildChangelogSection(
    version: version,
    commits: commits,
    latestTag: latestTag,
    packageName: packageName,
    allowedTypes: allowedTypes,
  );
  if (sectionResult.errorMessage != null) {
    return (
      changelog: null,
      section: null,
      errorMessage: sectionResult.errorMessage,
    );
  }

  return (
    changelog: prependChangelogSection(
      existingChangelog: existingChangelog,
      section: sectionResult.section!,
    ),
    section: sectionResult.section,
    errorMessage: null,
  );
}

/// Why the release safety gate rejected a bump.
enum ReleaseSafetyFailure {
  noReleaseTag,
  pubspecAheadOfTag,
  pubspecBehindTag,
}

/// A git commit entry collected from `git log <tag>..HEAD`.
class GitCommitEntry {
  const GitCommitEntry({
    required this.subject,
    this.body,
  });

  final String subject;
  final String? body;
}

/// Validates the tag-based release safety gate.
///
/// When [allowUnsafeBump] is `true`, version mismatches are allowed but a
/// matching release tag must still exist.
({bool passed, ReleaseSafetyFailure? failure, String? errorMessage})
    checkReleaseSafetyGate({
  required Version currentVersion,
  required String? latestTag,
  required Version? latestTagVersion,
  required String tagFormat,
  required String packageName,
  bool allowUnsafeBump = false,
}) {
  final expectedTag = renderTagFormat(
    format: tagFormat,
    name: packageName,
    version: currentVersion.toString(),
  );

  if (latestTag == null || latestTagVersion == null) {
    return (
      passed: false,
      failure: ReleaseSafetyFailure.noReleaseTag,
      errorMessage: 'No release tag found for package $packageName. '
          'An existing release tag is required before preparing a new release. '
          'Expected tag for current version $currentVersion: $expectedTag.',
    );
  }

  if (allowUnsafeBump || currentVersion == latestTagVersion) {
    return (passed: true, failure: null, errorMessage: null);
  }

  if (currentVersion > latestTagVersion) {
    return (
      passed: false,
      failure: ReleaseSafetyFailure.pubspecAheadOfTag,
      errorMessage:
          'Package version $currentVersion is ahead of latest release '
          'tag $latestTag ($latestTagVersion). '
          'Expected tag for current version: $expectedTag.',
    );
  }

  return (
    passed: false,
    failure: ReleaseSafetyFailure.pubspecBehindTag,
    errorMessage:
        'Package version $currentVersion is behind latest release tag '
        '$latestTag ($latestTagVersion). Update pubspec version to match the '
        'latest tag or pass --allow-unsafe-bump for local recovery.',
  );
}

/// Resolves the latest release tag and validates the safety gate.
({String? latestTag, Version? latestTagVersion, String? errorMessage})
    resolveLatestTagWithSafetyGate({
  required Directory gitRoot,
  required String tagFormat,
  required String packageName,
  required Version currentVersion,
  bool allowUnsafeBump = false,
}) {
  final latestTagResult = resolveLatestTag(
    gitRoot: gitRoot,
    tagFormat: tagFormat,
    packageName: packageName,
  );
  if (latestTagResult.errorMessage != null) {
    return (
      latestTag: null,
      latestTagVersion: null,
      errorMessage: latestTagResult.errorMessage,
    );
  }

  final safetyResult = checkReleaseSafetyGate(
    currentVersion: currentVersion,
    latestTag: latestTagResult.tag,
    latestTagVersion: latestTagResult.version,
    tagFormat: tagFormat,
    packageName: packageName,
    allowUnsafeBump: allowUnsafeBump,
  );
  if (!safetyResult.passed) {
    return (
      latestTag: latestTagResult.tag,
      latestTagVersion: latestTagResult.version,
      errorMessage: safetyResult.errorMessage,
    );
  }

  return (
    latestTag: latestTagResult.tag,
    latestTagVersion: latestTagResult.version,
    errorMessage: null,
  );
}

const _gitCommitRecordDelimiter = '---COMMIT---';

/// Collects commits from `git log <latestTag>..HEAD`.
///
/// Returns entries in chronological order (oldest first).
({List<GitCommitEntry>? commits, String? errorMessage}) collectCommitsSinceTag({
  required Directory gitRoot,
  required String latestTag,
}) {
  final result = Process.runSync(
    'git',
    [
      '-C',
      gitRoot.path,
      'log',
      '$latestTag..HEAD',
      '--reverse',
      '--format=%s%n%b%n$_gitCommitRecordDelimiter',
    ],
  );
  if (result.exitCode != 0) {
    final stderrText = result.stderr.toString().trim();
    return (
      commits: null,
      errorMessage: stderrText.isEmpty
          ? 'Failed to collect commits since tag $latestTag.'
          : 'Failed to collect commits since tag $latestTag: $stderrText',
    );
  }

  final stdoutText = result.stdout.toString();
  if (stdoutText.trim().isEmpty) {
    return (commits: const [], errorMessage: null);
  }

  final commits = <GitCommitEntry>[];
  for (final rawRecord in stdoutText.split('$_gitCommitRecordDelimiter\n')) {
    final record = rawRecord.trim();
    if (record.isEmpty) {
      continue;
    }

    final lines = record.split('\n');
    final subject = lines.first.trim();
    if (subject.isEmpty) {
      continue;
    }

    final bodyLines = lines.skip(1).toList();
    while (bodyLines.isNotEmpty && bodyLines.last.trim().isEmpty) {
      bodyLines.removeLast();
    }
    final body = bodyLines.isEmpty ? null : bodyLines.join('\n');

    commits.add(GitCommitEntry(subject: subject, body: body));
  }

  return (commits: commits, errorMessage: null);
}

/// Parses [entries] into conventional commits, preserving commit bodies.
List<ConventionalCommit> parseConventionalCommits(
  Iterable<GitCommitEntry> entries,
) {
  final commits = <ConventionalCommit>[];

  for (final entry in entries) {
    final parsed = parseConventionalCommitSubject(entry.subject);
    if (parsed == null) {
      continue;
    }

    commits.add(
      ConventionalCommit(
        type: parsed.type,
        scopes: parsed.scopes,
        description: parsed.description,
        subject: parsed.subject,
        isBreakingChange: parsed.isBreakingChange,
        body: entry.body,
      ),
    );
  }

  return commits;
}

/// Collects scoped conventional commits since [latestTag].
({List<ConventionalCommit>? commits, String? errorMessage})
    collectScopedCommitsSinceTag({
  required Directory gitRoot,
  required String latestTag,
  required String packageName,
  required Set<String> allowedTypes,
}) {
  final logResult = collectCommitsSinceTag(
    gitRoot: gitRoot,
    latestTag: latestTag,
  );
  if (logResult.errorMessage != null) {
    return (commits: null, errorMessage: logResult.errorMessage);
  }

  final parsed = parseConventionalCommits(logResult.commits!);
  final filtered = filterConventionalCommits(
    subjects: parsed.map((commit) => commit.subject),
    packageName: packageName,
    allowedTypes: allowedTypes,
  );
  final bodiesBySubject = {
    for (final commit in parsed) commit.subject: commit.body,
  };

  return (
    commits: [
      for (final commit in filtered)
        ConventionalCommit(
          type: commit.type,
          scopes: commit.scopes,
          description: commit.description,
          subject: commit.subject,
          isBreakingChange: commit.isBreakingChange,
          body: bodiesBySubject[commit.subject],
        ),
    ],
    errorMessage: null,
  );
}
