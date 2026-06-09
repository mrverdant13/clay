import 'dart:io';

import 'package:path/path.dart' as p;

/// A temporary project layout for e2e CLI tests.
class E2eFixtureProject {
  E2eFixtureProject._(this.root);

  /// Project root containing `brick-gen.json`.
  final Directory root;

  /// Reference directory under [root].
  Directory get referenceDir => Directory(p.join(root.path, 'reference'));

  /// Target directory under [root].
  Directory get targetDir => Directory(p.join(root.path, 'target'));

  /// Creates a fixture with [configJson] and [referenceFiles].
  static E2eFixtureProject create({
    String? configJson,
    Map<String, String> referenceFiles = const {},
  }) {
    final root = Directory.systemTemp.createTempSync('clay_e2e_');
    File(p.join(root.path, 'brick-gen.json')).writeAsStringSync(
      configJson ??
          '''
{
  "reference": "reference",
  "target": "target"
}
''',
    );

    final referenceDir = Directory(p.join(root.path, 'reference'))
      ..createSync(recursive: true);

    for (final entry in referenceFiles.entries) {
      final file = File(p.join(referenceDir.path, entry.key))
        ..createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }

    return E2eFixtureProject._(root);
  }

  /// Deletes the temporary project tree.
  void dispose() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
