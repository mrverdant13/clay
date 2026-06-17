import 'dart:io';

import 'package:test/test.dart';

import '../sync_package_version.dart';

void main() {
  late Directory repoRoot;
  late Directory packageDir;

  setUp(() {
    repoRoot =
        Directory.systemTemp.createTempSync('clay_sync_package_version_');
    packageDir = Directory('${repoRoot.path}/packages/example')
      ..createSync(recursive: true);
    Directory('${packageDir.path}/lib/src').createSync(recursive: true);
  });

  tearDown(() {
    if (repoRoot.existsSync()) {
      repoRoot.deleteSync(recursive: true);
    }
  });

  test('updates version const when pubspec version differs', () {
    File('${packageDir.path}/pubspec.yaml').writeAsStringSync('''
name: example
version: 1.2.3
''');
    File('${packageDir.path}/lib/src/version.dart').writeAsStringSync('''
const exampleVersion = '1.0.0';
''');

    final exitCode = syncPackageVersion(
      const PackageConfig(
        packagePath: 'packages/example',
        versionConstName: 'exampleVersion',
      ),
      repoRoot,
    );

    expect(exitCode, 0);
    expect(
      File('${packageDir.path}/lib/src/version.dart').readAsStringSync(),
      contains("const exampleVersion = '1.2.3';"),
    );
  });

  test('is a no-op when version const already matches pubspec', () {
    File('${packageDir.path}/pubspec.yaml').writeAsStringSync('''
name: example
version: 1.2.3
''');
    final versionDartPath = '${packageDir.path}/lib/src/version.dart';
    const versionDartContents = "const exampleVersion = '1.2.3';\n";
    File(versionDartPath).writeAsStringSync(versionDartContents);

    final exitCode = syncPackageVersion(
      const PackageConfig(
        packagePath: 'packages/example',
        versionConstName: 'exampleVersion',
      ),
      repoRoot,
    );

    expect(exitCode, 0);
    expect(File(versionDartPath).readAsStringSync(), versionDartContents);
  });

  test('fails when pubspec.yaml is missing', () {
    File('${packageDir.path}/lib/src/version.dart').writeAsStringSync('''
const exampleVersion = '1.0.0';
''');

    final exitCode = syncPackageVersion(
      const PackageConfig(
        packagePath: 'packages/example',
        versionConstName: 'exampleVersion',
      ),
      repoRoot,
    );

    expect(exitCode, 1);
  });

  test('fails when version const pattern is missing', () {
    File('${packageDir.path}/pubspec.yaml').writeAsStringSync('''
name: example
version: 1.2.3
''');
    File('${packageDir.path}/lib/src/version.dart').writeAsStringSync('''
const otherVersion = '1.2.3';
''');

    final exitCode = syncPackageVersion(
      const PackageConfig(
        packagePath: 'packages/example',
        versionConstName: 'exampleVersion',
      ),
      repoRoot,
    );

    expect(exitCode, 1);
  });
}
