import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Normalizes [relativePath] to a POSIX-style path relative to a scan root.
@visibleForTesting
String normalizeIgnoreRelativePath(String relativePath) {
  final normalized = relativePath.replaceAll(r'\', '/');
  final segments = p.posix.split(p.posix.normalize(normalized));
  return p.posix.joinAll(
    segments.where((segment) => segment.isNotEmpty && segment != '.'),
  );
}

/// Returns an error message when [pattern] is invalid for ignore matching.
///
/// Patterns must use POSIX-style forward slashes. Gitignore root anchors such
/// as `/build/` refer to the reference or target root, not the OS filesystem
/// root.
@visibleForTesting
String? ignorePatternValidationError(String pattern) {
  var body = pattern;
  if (body.startsWith('!')) {
    body = body.substring(1);
  }
  if (body.isEmpty) {
    return null;
  }

  if (body.contains(r'\')) {
    return 'ignore pattern must use POSIX-style forward slashes: $pattern';
  }
  if (RegExp('^[a-zA-Z]:/').hasMatch(body)) {
    return 'ignore pattern must be relative to the scan root; '
        'Windows-absolute paths are not allowed: $pattern';
  }
  if (body.startsWith('//')) {
    return 'ignore pattern must be relative to the scan root; '
        'use a single leading / to anchor to the scan root: $pattern';
  }

  return null;
}

/// Validates [patterns] for ignore matching.
///
/// Throws [FormatException] when a pattern is invalid.
void validateIgnorePatterns(List<String> patterns) {
  for (final pattern in patterns) {
    final error = ignorePatternValidationError(pattern);
    if (error != null) {
      throw FormatException(error);
    }
  }
}

/// Returns the normalized path of [absolutePath] relative to [rootDirectory].
///
/// Returns `null` when [absolutePath] is outside [rootDirectory].
@visibleForTesting
String? relativePathWithinRoot({
  required String rootDirectory,
  required String absolutePath,
}) {
  final relative = p.normalize(p.relative(absolutePath, from: rootDirectory));
  if (p.isAbsolute(relative)) {
    return null;
  }
  final normalized = normalizeIgnoreRelativePath(relative);
  if (normalized == '..' || normalized.startsWith('../')) {
    return null;
  }
  return normalized;
}

/// Expands a gitignore-style [pattern] into glob patterns for matching.
@visibleForTesting
List<String> expandIgnorePattern(String pattern) {
  var rootAnchored = false;
  var body = pattern;
  if (body.startsWith('/')) {
    rootAnchored = true;
    body = body.substring(1);
  }

  var directoryOnly = false;
  if (body.endsWith('/')) {
    directoryOnly = true;
    body = body.substring(0, body.length - 1);
  }

  if (body.isEmpty) {
    return const [];
  }

  final hasSlash = body.contains('/');
  final anchored = rootAnchored || hasSlash;

  if (directoryOnly) {
    if (anchored) {
      return [body, '$body/**'];
    }
    return [
      body,
      '$body/**',
      '**/$body',
      '**/$body/**',
    ];
  }

  if (!anchored) {
    return [body, '**/$body'];
  }

  if (body.startsWith('**/')) {
    return [body, body.substring(3)];
  }

  return [body];
}

/// Returns whether [relativePath] matches a single gitignore-style [pattern].
@visibleForTesting
bool matchesIgnorePattern({
  required String relativePath,
  required String pattern,
}) {
  final normalizedPath = normalizeIgnoreRelativePath(relativePath);
  final globPatterns = expandIgnorePattern(pattern);

  return globPatterns.any(
    (globPattern) =>
        Glob(globPattern, context: p.posix).matches(normalizedPath),
  );
}

/// Returns whether [relativePath] is excluded by [patterns].
///
/// [relativePath] must be relative to the scan root (reference or target).
/// [patterns] use gitignore-compatible syntax, including `!` negation.
bool matchesIgnorePatterns({
  required String relativePath,
  required List<String> patterns,
}) {
  if (patterns.isEmpty) {
    return false;
  }

  final normalizedPath = normalizeIgnoreRelativePath(relativePath);
  var ignored = false;

  for (final pattern in patterns) {
    if (pattern.startsWith('!')) {
      if (matchesIgnorePattern(
        relativePath: normalizedPath,
        pattern: pattern.substring(1),
      )) {
        ignored = false;
      }
    } else if (matchesIgnorePattern(
      relativePath: normalizedPath,
      pattern: pattern,
    )) {
      ignored = true;
    }
  }

  return ignored;
}

/// Returns whether [absolutePath] under [rootDirectory] is excluded by
/// [patterns].
bool shouldIgnoreAtRoot({
  required String rootDirectory,
  required String absolutePath,
  required List<String> patterns,
}) {
  final relativePath = relativePathWithinRoot(
    rootDirectory: rootDirectory,
    absolutePath: absolutePath,
  );
  if (relativePath == null) {
    return false;
  }

  return matchesIgnorePatterns(
    relativePath: relativePath,
    patterns: patterns,
  );
}
