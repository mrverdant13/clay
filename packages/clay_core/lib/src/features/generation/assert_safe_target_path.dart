import 'dart:io';

import 'package:clay_core/src/features/generation/generation_exception.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Ensures [targetPath] is not the filesystem root.
///
/// Throws [GenerationException] when [targetPath] resolves to `/` on POSIX
/// systems or a drive root such as `C:\` on Windows.
void assertSafeTargetPath({required String targetPath}) {
  final normalizedTarget = p.normalize(p.absolute(targetPath));
  if (isFilesystemRoot(normalizedTarget)) {
    throw GenerationException(
      'Target path cannot be the filesystem root ($targetPath).',
    );
  }
}

/// Returns whether [normalizedAbsolutePath] is a filesystem root.
@visibleForTesting
bool isFilesystemRoot(
  String normalizedAbsolutePath, {
  bool? isWindows,
}) {
  final onWindows = isWindows ?? Platform.isWindows;
  if (onWindows) {
    return RegExp(r'^[A-Za-z]:[/\\]?$').hasMatch(normalizedAbsolutePath);
  }
  return normalizedAbsolutePath == p.posix.separator;
}
