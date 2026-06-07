import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Copies [file] to [destinationPath], creating parent directories as needed.
@visibleForTesting
Future<void> copyFileToDestination({
  required File file,
  required String destinationPath,
}) async {
  final parent = Directory(p.dirname(destinationPath));
  if (!parent.existsSync()) {
    await parent.create(recursive: true);
  }
  await file.copy(destinationPath);
}

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
      await copyFileToDestination(
        file: entity,
        destinationPath: destinationPath,
      );
    }
  }
}
