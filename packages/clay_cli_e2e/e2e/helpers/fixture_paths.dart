/// Suffix for committed reference sources (deployed as `.dart` in working
/// copies).
const fixtureReferenceSuffix = '.dart.ref';

/// Suffix for committed golden outputs (compared as `.dart` paths).
const fixtureGoldenSuffix = '.dart.golden';

/// Returns the working-tree file name for a committed reference fixture file.
String referenceTargetFileName(String fixtureFileName) {
  if (fixtureFileName.endsWith(fixtureReferenceSuffix)) {
    return fixtureFileName.substring(
      0,
      fixtureFileName.length - '.ref'.length,
    );
  }
  return fixtureFileName;
}

/// Returns the logical output path for a golden fixture file on disk.
String goldenLogicalPath(String fixtureRelativePath) {
  if (fixtureRelativePath.endsWith(fixtureGoldenSuffix)) {
    return fixtureRelativePath.substring(
      0,
      fixtureRelativePath.length - '.golden'.length,
    );
  }
  return fixtureRelativePath;
}

/// Returns the on-disk golden path for a logical generated file path.
String goldenDiskRelativePath(String logicalRelativePath) {
  if (logicalRelativePath.endsWith('.dart')) {
    return '$logicalRelativePath.golden';
  }
  return logicalRelativePath;
}
