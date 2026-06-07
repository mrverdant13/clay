import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/features/config/matches_ignore_pattern.dart';
import 'package:clay_cli/src/features/generation/prune_empty_directories.dart';
import 'package:clay_cli/src/features/generation/resolve_target_file_path.dart';
import 'package:clay_cli/src/features/transforms/resolve_reference_content.dart';
import 'package:clay_cli/src/features/transforms/skip_content_transforms.dart';
import 'package:path/path.dart' as p;

/// Applies ignore rules, path renames, and content transforms to [file].
Future<void> processTargetFile({
  required File file,
  required String targetAbsolutePath,
  required BrickGenConfig config,
}) async {
  if (shouldIgnoreAtRoot(
    rootDirectory: targetAbsolutePath,
    absolutePath: file.path,
    patterns: config.ignore,
  )) {
    final parent = file.parent;
    if (file.existsSync()) {
      await file.delete();
    }
    pruneEmptyParentDirectories(
      startingDirectory: parent,
      stopAt: Directory(targetAbsolutePath),
    );
    return;
  }

  final resolvedPath = resolveTargetFilePath(
    absolutePath: file.path,
    targetAbsolutePath: targetAbsolutePath,
    replacements: config.replacements,
  );

  final resultingFile = await () async {
    if (p.equals(resolvedPath, file.path)) {
      return file;
    }
    final dir = Directory(p.dirname(resolvedPath));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return file.rename(resolvedPath);
  }();

  await _resolveTargetFileContents(
    file: resultingFile,
    targetAbsolutePath: targetAbsolutePath,
    config: config,
  );
}

Future<void> _resolveTargetFileContents({
  required File file,
  required String targetAbsolutePath,
  required BrickGenConfig config,
}) async {
  final targetRelativePath = p.relative(
    file.path,
    from: targetAbsolutePath,
  );
  if (shouldSkipContentTransforms(targetRelativePath)) {
    return;
  }

  final content = await file.readAsString();
  final resolvedContent = resolveReferenceContent(
    content: content,
    targetRelativePath: targetRelativePath,
    targetAbsolutePath: targetAbsolutePath,
    config: config,
  );
  await file.writeAsString(resolvedContent);
}
