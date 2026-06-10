import 'dart:io';

import 'package:path/path.dart' as p;

/// Locates `packages/clay_cli_e2e` from the current working directory.
Directory e2ePackageRoot() {
  var current = Directory.current;
  while (true) {
    final pubspec = File(p.join(current.path, 'pubspec.yaml'));
    if (pubspec.existsSync() &&
        pubspec.readAsStringSync().contains('name: clay_cli_e2e')) {
      return current;
    }

    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError(
        'Could not locate clay_cli_e2e package root from ${Directory.current.path}',
      );
    }
    current = parent;
  }
}

/// A self-contained integration fixture under `e2e/fixtures/integration/`.
class IntegrationFixture {
  IntegrationFixture._({
    required this.name,
    required this.packageRoot,
    required this.root,
    required this.workingRoot,
  });

  /// Loads fixture [name] into a temporary working directory.
  factory IntegrationFixture.load(String name) {
    final packageRoot = e2ePackageRoot();
    final fixtureRoot = Directory(
      p.join(packageRoot.path, 'e2e', 'fixtures', 'integration', name),
    );
    if (!fixtureRoot.existsSync()) {
      throw ArgumentError('Unknown integration fixture: $name');
    }

    final workingRoot =
        Directory.systemTemp.createTempSync('clay_integration_$name');
    _copyDirectory(fixtureRoot, workingRoot);

    return IntegrationFixture._(
      name: name,
      packageRoot: packageRoot,
      root: fixtureRoot,
      workingRoot: workingRoot,
    );
  }

  /// Fixture identifier (directory name).
  final String name;

  /// `clay_cli_e2e` package root.
  final Directory packageRoot;

  /// Committed fixture tree (includes `expected/`).
  final Directory root;

  /// Temporary copy used during tests (`expected/` is removed).
  final Directory workingRoot;

  /// `brick-gen.json` in the working copy.
  File get configFile => File(p.join(workingRoot.path, 'brick-gen.json'));

  /// Reference directory in the working copy.
  Directory get referenceDir =>
      Directory(p.join(workingRoot.path, 'reference'));

  /// Target directory in the working copy (created by generation).
  Directory get targetDir => Directory(p.join(workingRoot.path, 'target'));

  /// Golden expected output committed with the fixture.
  Directory get expectedDir => Directory(p.join(root.path, 'expected'));

  /// Deletes the temporary working directory.
  void dispose() {
    if (workingRoot.existsSync()) {
      workingRoot.deleteSync(recursive: true);
    }
  }

  static void _copyDirectory(Directory source, Directory destination) {
    for (final entity in source.listSync(recursive: false)) {
      final targetPath = p.join(destination.path, p.basename(entity.path));
      if (entity is File) {
        if (p.basename(entity.path) == 'expected') {
          continue;
        }
        entity.copySync(targetPath);
      } else if (entity is Directory) {
        if (p.basename(entity.path) == 'expected') {
          continue;
        }
        final targetDir = Directory(targetPath)..createSync(recursive: true);
        _copyDirectory(entity, targetDir);
      }
    }
  }
}

/// Reads a committed preview expectation file from [fixtureRoot].
String readPreviewExpectation({
  required Directory fixtureRoot,
  required String fileName,
}) {
  final file = File(p.join(fixtureRoot.path, 'preview', fileName));
  if (!file.existsSync()) {
    throw ArgumentError('Missing preview expectation: $fileName');
  }
  return file.readAsStringSync();
}
