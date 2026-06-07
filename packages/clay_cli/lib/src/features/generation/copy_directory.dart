import 'dart:io';

import 'package:path/path.dart' as p;

/// Recursively copies [source] into [destination].
Future<void> copyDirectory({
  required Directory source,
  required Directory destination,
}) async {
  if (!destination.existsSync()) {
    await destination.create(recursive: true);
  }

  await for (final entity in source.list()) {
    final destinationPath = p.join(
      destination.path,
      p.basename(entity.path),
    );
    if (entity is Directory) {
      await copyDirectory(
        source: entity,
        destination: Directory(destinationPath),
      );
    } else if (entity is File) {
      final parent = Directory(p.dirname(destinationPath));
      if (!parent.existsSync()) {
        await parent.create(recursive: true);
      }
      await entity.copy(destinationPath);
    }
  }
}
