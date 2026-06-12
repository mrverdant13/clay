import 'dart:io';

import 'package:path/path.dart' as p;

/// A temporary project layout for e2e CLI tests.
class E2eFixtureProject {
  E2eFixtureProject._(this.root);

  /// Creates a fixture with [configYaml] and [referenceFiles].
  factory E2eFixtureProject.withFiles({
    String? configYaml,
    Map<String, String> referenceFiles = const {},
  }) {
    final root = Directory.systemTemp.createTempSync('clay_e2e_');
    File(p.join(root.path, 'clay.yaml')).writeAsStringSync(
      configYaml ??
          '''
reference: reference
target: target
''',
    );

    final referenceDir = Directory(p.join(root.path, 'reference'))
      ..createSync(recursive: true);

    for (final entry in referenceFiles.entries) {
      File(p.join(referenceDir.path, entry.key))
        ..createSync(recursive: true)
        ..writeAsStringSync(entry.value);
    }

    return E2eFixtureProject._(root);
  }

  /// Project root containing `clay.yaml`.
  final Directory root;

  /// Reference directory under [root].
  Directory get referenceDir => Directory(p.join(root.path, 'reference'));

  /// Target directory under [root].
  Directory get targetDir => Directory(p.join(root.path, 'target'));

  /// Deletes the temporary project tree.
  void dispose() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
