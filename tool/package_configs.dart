/// Hardcoded package metadata for release tooling that has not yet adopted
/// `--cwd`. Used by `release_tag.dart` and `wait_for_pub_dev_version.dart`.
const packageConfigs = <String, PackageConfig>{
  'clay_core': PackageConfig(
    packagePath: 'packages/clay_core',
    versionConstName: 'clayCoreVersion',
  ),
  'clay_cli': PackageConfig(
    packagePath: 'packages/clay_cli',
    versionConstName: 'packageVersion',
  ),
};

class PackageConfig {
  const PackageConfig({
    required this.packagePath,
    required this.versionConstName,
  });

  final String packagePath;
  final String versionConstName;
}
