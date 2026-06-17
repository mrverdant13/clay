import 'dart:io';

import 'package:clay_cli/src/version.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

final _clayCliPackageNamePattern =
    RegExp(r'^name:\s+clay_cli\s*$', multiLine: true);

final _pubspecVersionPattern = RegExp(
  r'^version:\s+(\S+)\s*$',
  multiLine: true,
);

Directory _packageRoot() {
  var current = Directory.current;
  while (true) {
    final pubspec = File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync() &&
        _clayCliPackageNamePattern.hasMatch(pubspec.readAsStringSync())) {
      return current;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      fail(
        'Could not locate clay_cli package root from '
        '${Directory.current.path}',
      );
    }
    current = parent;
  }
}

String _readPubspecVersion(Directory packageRoot) {
  final pubspecPath = p.join(packageRoot.path, 'pubspec.yaml');
  final pubspecContents = File(pubspecPath).readAsStringSync();
  final match = _pubspecVersionPattern.firstMatch(pubspecContents);
  if (match == null) {
    fail('Expected pubspec.yaml at $pubspecPath to declare a version field');
  }

  final version = match.group(1)!;
  if (version.isEmpty) {
    fail('Expected pubspec.yaml version to be a non-empty string');
  }

  return version;
}

void main() {
  test('pubspec.yaml version matches packageVersion', () {
    final pubspecVersion = _readPubspecVersion(_packageRoot());

    expect(
      packageVersion,
      pubspecVersion,
      reason: 'packageVersion ($packageVersion) must match '
          'pubspec.yaml version ($pubspecVersion). '
          'Update lib/src/version.dart after bumping pubspec.yaml, or run '
          'dart run tool/sync_package_version.dart --package clay_cli '
          'once the sync script is available.',
    );
  });
}
