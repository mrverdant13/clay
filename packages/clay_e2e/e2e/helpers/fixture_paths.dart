/// Path suffix conventions for integration fixture files.
///
/// Reference and golden fixtures that contain clay template syntax (mustache
/// tags, annotation markers, and similar) must **not** use normal `.dart` or
/// `.yaml` extensions on disk. Those files would be parsed by `dart format`
/// and `dart analyze` and cause tooling failures.
///
/// Instead, committed files use extra suffixes:
///
/// - `.ref` — reference source; stripped when copied to a working directory
///   (e.g. `widget.dart.ref` → `widget.dart`).
/// - `.golden` — expected output; compared under the logical path after
///   generation (e.g. `widget.dart.golden` ↔ `widget.dart`).
library;

/// Suffix appended to committed reference sources (stripped in working copies).
const fixtureReferenceSuffix = '.ref';

/// Suffix appended to committed golden outputs (stripped for comparisons).
const fixtureGoldenSuffix = '.golden';

/// File extensions stored on disk with [fixtureGoldenSuffix].
const goldenSuffixExtensions = ['.dart', '.yaml'];

/// Returns the working-tree file name for a committed reference fixture file.
String referenceTargetFileName(String fixtureFileName) {
  if (fixtureFileName.endsWith(fixtureReferenceSuffix)) {
    return fixtureFileName.substring(
      0,
      fixtureFileName.length - fixtureReferenceSuffix.length,
    );
  }
  return fixtureFileName;
}

/// Returns the logical output path for a golden fixture file on disk.
String goldenLogicalPath(String fixtureRelativePath) {
  if (fixtureRelativePath.endsWith(fixtureGoldenSuffix)) {
    return fixtureRelativePath.substring(
      0,
      fixtureRelativePath.length - fixtureGoldenSuffix.length,
    );
  }
  return fixtureRelativePath;
}

/// Whether [logicalRelativePath] is stored with [fixtureGoldenSuffix] on disk.
bool usesGoldenDiskSuffix(String logicalRelativePath) {
  return goldenSuffixExtensions.any(logicalRelativePath.endsWith);
}

/// Returns the on-disk golden path for a logical generated file path.
String goldenDiskRelativePath(String logicalRelativePath) {
  if (usesGoldenDiskSuffix(logicalRelativePath)) {
    return '$logicalRelativePath$fixtureGoldenSuffix';
  }
  return logicalRelativePath;
}
