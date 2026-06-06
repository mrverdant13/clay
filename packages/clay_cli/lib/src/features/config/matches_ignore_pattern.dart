import 'package:glob/glob.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Normalizes [relativePath] to a POSIX-style path relative to the reference
/// root.
@visibleForTesting
String normalizeIgnoreRelativePath(String relativePath) {
  final normalized = relativePath.replaceAll(r'\', '/');
  final segments = p.posix.split(p.posix.normalize(normalized));
  return p.posix.joinAll(
    segments.where((segment) => segment.isNotEmpty && segment != '.'),
  );
}

/// Expands a gitignore-style [pattern] into glob patterns for matching.
@visibleForTesting
List<String> expandIgnorePattern(String pattern) {
  var rootAnchored = false;
  if (pattern.startsWith('/')) {
    rootAnchored = true;
    pattern = pattern.substring(1);
  }

  var directoryOnly = false;
  if (pattern.endsWith('/')) {
    directoryOnly = true;
    pattern = pattern.substring(0, pattern.length - 1);
  }

  if (pattern.isEmpty) {
    return const [];
  }

  final hasSlash = pattern.contains('/');
  final anchored = rootAnchored || hasSlash;

  if (directoryOnly) {
    if (anchored) {
      return [pattern, '$pattern/**'];
    }
    return [
      pattern,
      '$pattern/**',
      '**/$pattern',
      '**/$pattern/**',
    ];
  }

  if (!anchored) {
    return [pattern, '**/$pattern'];
  }

  if (pattern.startsWith('**/')) {
    return [pattern, pattern.substring(3)];
  }

  return [pattern];
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
/// [relativePath] must be relative to the reference directory root.
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
