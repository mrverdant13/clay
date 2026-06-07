import 'dart:io';

import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:path/path.dart' as p;

/// Ensures [targetPath] is not the filesystem root.
///
/// Throws [GenerationException] when [targetPath] resolves to `/` on POSIX
/// systems or a drive root such as `C:\` on Windows.
void assertSafeTargetPath({required String targetPath}) {
  final normalizedTarget = p.normalize(p.absolute(targetPath));
  if (_isFilesystemRoot(normalizedTarget)) {
    throw GenerationException(
      'Target path cannot be the filesystem root ($targetPath).',
    );
  }
}

bool _isFilesystemRoot(String normalizedAbsolutePath) {
  if (Platform.isWindows) {
    return RegExp(r'^[A-Za-z]:[/\\]?$').hasMatch(normalizedAbsolutePath);
  }
  return normalizedAbsolutePath == p.separator;
}
