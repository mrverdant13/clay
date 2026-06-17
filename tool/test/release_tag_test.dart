import 'dart:io';

import 'package:test/test.dart';

import '../release_tag.dart';
import '../sync_package_version.dart';

void main() {
  late Directory repoRoot;

  setUp(() {
    repoRoot = Directory.systemTemp.createTempSync('clay_release_tag_');
  });

  tearDown(() {
    if (repoRoot.existsSync()) {
      repoRoot.deleteSync(recursive: true);
    }
  });

  test('builds annotated tag commands from pubspec version', () {
    _writePubspec(
      repoRoot: repoRoot,
      packagePath: 'packages/clay_core',
      version: '0.0.1-dev.2',
    );

    final result = buildReleaseTagPlan(
      'clay_core',
      packageConfigs['clay_core']!,
      repoRoot,
    );

    expect(result.errorMessage, isNull);
    final plan = result.plan!;
    expect(plan.tagName, 'clay_core/0.0.1-dev.2');
    expect(plan.tagMessage, 'clay_core 0.0.1-dev.2');
    expect(
      plan.printCommands(),
      '''
git tag -a clay_core/0.0.1-dev.2 -m 'clay_core 0.0.1-dev.2'
git push origin clay_core/0.0.1-dev.2''',
    );
  });

  test('fails when pubspec.yaml is missing', () {
    final result = buildReleaseTagPlan(
      'clay_cli',
      packageConfigs['clay_cli']!,
      repoRoot,
    );

    expect(result.plan, isNull);
    expect(result.errorMessage, contains('Missing pubspec.yaml'));
  });

  test('shell-quotes tag messages that need escaping', () {
    expect(
      formatShellCommand(['git', 'tag', '-a', 'clay_core/1.0.0', '-m', 'a b']),
      "git tag -a clay_core/1.0.0 -m 'a b'",
    );
  });
}

void _writePubspec({
  required Directory repoRoot,
  required String packagePath,
  required String version,
}) {
  final packageDir = Directory('${repoRoot.path}/$packagePath')
    ..createSync(recursive: true);
  File('${packageDir.path}/pubspec.yaml').writeAsStringSync('''
name: example
version: $version
''');
}
