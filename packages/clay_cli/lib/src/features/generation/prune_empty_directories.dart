import 'dart:io';

import 'package:path/path.dart' as p;

/// Deletes empty parent directories starting at [startingDirectory].
///
/// Stops when [stopAt] is reached or a non-empty directory is found.
void pruneEmptyParentDirectories({
  required Directory startingDirectory,
  required Directory stopAt,
}) {
  var current = startingDirectory;
  final normalizedStopAt = p.normalize(stopAt.path);

  while (true) {
    final normalizedCurrent = p.normalize(current.path);
    if (normalizedCurrent == normalizedStopAt) {
      return;
    }
    if (!p.isWithin(normalizedStopAt, normalizedCurrent)) {
      return;
    }
    if (!current.existsSync()) {
      current = current.parent;
      continue;
    }
    if (current.listSync(followLinks: false).isNotEmpty) {
      return;
    }

    final parent = current.parent;
    current.deleteSync();
    current = parent;
  }
}
