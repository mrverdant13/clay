import 'dart:io';

import 'package:clay/clay.dart';
import 'package:clay/src/features/config/matches_ignore_pattern.dart'
    show normalizeIgnoreRelativePath, shouldIgnoreAtRoot;
import 'package:clay/src/features/generation/assert_unique_resolved_paths.dart';
import 'package:clay/src/features/generation/prune_empty_directories.dart';
import 'package:clay/src/features/generation/resolve_target_file_path.dart';
import 'package:clay/src/features/transforms/skip_content_transforms.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Applies ignore rules, path renames, and content transforms to [file].
Future<void> processTargetFile({
  required File file,
  required String targetAbsolutePath,
  required BrickGenConfig config,
}) async {
  final normalizedTarget = p.normalize(p.absolute(targetAbsolutePath));
  final normalizedFilePath = p.normalize(p.absolute(file.path));

  if (_shouldIgnoreEntity(
    normalizedTarget: normalizedTarget,
    normalizedEntityPath: normalizedFilePath,
    patterns: config.ignore,
  )) {
    await _deleteEntityAndPruneParents(
      entity: file,
      normalizedTarget: normalizedTarget,
    );
    return;
  }

  final resolvedPath = resolveTargetFilePath(
    absolutePath: normalizedFilePath,
    targetAbsolutePath: normalizedTarget,
    replacements: config.replacements,
  );

  final resultingFile = await _renameEntity(
    entity: file,
    normalizedEntityPath: normalizedFilePath,
    resolvedPath: resolvedPath,
    normalizedTarget: normalizedTarget,
    ignorePatterns: config.ignore,
  );

  await _resolveTargetFileContents(
    file: resultingFile,
    targetAbsolutePath: normalizedTarget,
    config: config,
  );
}

/// Applies ignore rules, staged path renames, and content transforms to
/// copied entries.
@internal
Future<void> processCopiedTargetEntities({
  required List<FileSystemEntity> targetEntities,
  required String normalizedTargetPath,
  required BrickGenConfig config,
  void Function(String relativePath)? onIgnoredFile,
}) async {
  final normalizedTarget = p.normalize(p.absolute(normalizedTargetPath));
  final resolvedPaths = <String, String>{};

  for (final entity in targetEntities) {
    if (entity is! File && entity is! Link) {
      throw StateError('Unexpected entity type: ${entity.runtimeType}');
    }
  }

  for (final entity in targetEntities) {
    registerResolvedPath(
      resolvedPaths: resolvedPaths,
      entityPath: entity.path,
      targetAbsolutePath: normalizedTarget,
      config: config,
    );
  }

  for (final entity in targetEntities) {
    await _deleteTargetEntityWhenIgnored(
      entity: entity,
      normalizedTarget: normalizedTarget,
      patterns: config.ignore,
      onIgnoredFile: onIgnoredFile,
    );
  }

  final renamePlan = <FileSystemEntity, String>{};
  for (final entity in targetEntities) {
    if (!entity.existsSync()) {
      continue;
    }

    final normalizedEntityPath = p.normalize(p.absolute(entity.path));
    if (_shouldIgnoreEntity(
      normalizedTarget: normalizedTarget,
      normalizedEntityPath: normalizedEntityPath,
      patterns: config.ignore,
    )) {
      continue;
    }

    renamePlan[entity] = resolveTargetFilePath(
      absolutePath: normalizedEntityPath,
      targetAbsolutePath: normalizedTarget,
      replacements: config.replacements,
    );
  }

  final stagedPaths = <String, String>{};
  final stageDir = Directory(p.join(normalizedTarget, '.clay-stage'));
  var stageIndex = 0;

  for (final entry in renamePlan.entries) {
    final entity = entry.key;
    final resolvedPath = entry.value;
    final normalizedEntityPath = p.normalize(p.absolute(entity.path));

    if (p.equals(resolvedPath, normalizedEntityPath)) {
      stagedPaths[normalizedEntityPath] = resolvedPath;
      continue;
    }

    if (!stageDir.existsSync()) {
      await stageDir.create(recursive: true);
    }

    final stagePath = p.join(stageDir.path, '$stageIndex');
    stageIndex++;
    await _renameEntity(
      entity: entity,
      normalizedEntityPath: normalizedEntityPath,
      resolvedPath: stagePath,
      normalizedTarget: normalizedTarget,
      ignorePatterns: config.ignore,
    );
    stagedPaths[stagePath] = resolvedPath;
  }

  for (final entry in stagedPaths.entries) {
    final currentPath = entry.key;
    final finalPath = entry.value;
    if (p.equals(currentPath, finalPath)) {
      continue;
    }

    final entity = entityAtPath(currentPath);
    if (entity == null) {
      continue;
    }

    await _renameEntity(
      entity: entity,
      normalizedEntityPath: p.normalize(p.absolute(currentPath)),
      resolvedPath: finalPath,
      normalizedTarget: normalizedTarget,
      ignorePatterns: config.ignore,
    );
  }

  if (stageDir.existsSync()) {
    await stageDir.delete(recursive: true);
  }

  for (final finalPath in stagedPaths.values.toSet()) {
    final entity = entityAtPath(finalPath);
    if (entity is File) {
      await _resolveTargetFileContents(
        file: entity,
        targetAbsolutePath: normalizedTarget,
        config: config,
      );
    }
  }
}

Future<void> _deleteTargetEntityWhenIgnored({
  required FileSystemEntity entity,
  required String normalizedTarget,
  required List<String> patterns,
  void Function(String relativePath)? onIgnoredFile,
}) async {
  final normalizedEntityPath = p.normalize(p.absolute(entity.path));
  if (!_shouldIgnoreEntity(
    normalizedTarget: normalizedTarget,
    normalizedEntityPath: normalizedEntityPath,
    patterns: patterns,
  )) {
    return;
  }

  onIgnoredFile?.call(
    normalizeIgnoreRelativePath(
      p.relative(normalizedEntityPath, from: normalizedTarget),
    ),
  );

  await _deleteEntityAndPruneParents(
    entity: entity,
    normalizedTarget: normalizedTarget,
  );
}

/// Applies ignore rules and path renames to [link].
Future<void> processTargetLink({
  required Link link,
  required String targetAbsolutePath,
  required BrickGenConfig config,
}) async {
  final normalizedTarget = p.normalize(p.absolute(targetAbsolutePath));
  final normalizedLinkPath = p.normalize(p.absolute(link.path));

  if (_shouldIgnoreEntity(
    normalizedTarget: normalizedTarget,
    normalizedEntityPath: normalizedLinkPath,
    patterns: config.ignore,
  )) {
    await _deleteEntityAndPruneParents(
      entity: link,
      normalizedTarget: normalizedTarget,
    );
    return;
  }

  final resolvedPath = resolveTargetFilePath(
    absolutePath: normalizedLinkPath,
    targetAbsolutePath: normalizedTarget,
    replacements: config.replacements,
  );

  await _renameEntity(
    entity: link,
    normalizedEntityPath: normalizedLinkPath,
    resolvedPath: resolvedPath,
    normalizedTarget: normalizedTarget,
    ignorePatterns: config.ignore,
  );
}

bool _shouldIgnoreEntity({
  required String normalizedTarget,
  required String normalizedEntityPath,
  required List<String> patterns,
}) {
  return shouldIgnoreAtRoot(
    rootDirectory: normalizedTarget,
    absolutePath: normalizedEntityPath,
    patterns: patterns,
  );
}

Future<void> _deleteEntityAndPruneParents({
  required FileSystemEntity entity,
  required String normalizedTarget,
}) async {
  final parent = entity.parent;
  if (entity.existsSync()) {
    if (entity is Directory) {
      await entity.delete(recursive: true);
    } else {
      await entity.delete();
    }
  }
  pruneEmptyParentDirectories(
    startingDirectory: parent,
    stopAt: Directory(normalizedTarget),
  );
}

Future<T> _renameEntity<T extends FileSystemEntity>({
  required T entity,
  required String normalizedEntityPath,
  required String resolvedPath,
  required String normalizedTarget,
  required List<String> ignorePatterns,
}) async {
  if (p.equals(resolvedPath, normalizedEntityPath)) {
    return entity;
  }

  await _deleteIgnoredDestinationIfPresent(
    resolvedPath: resolvedPath,
    normalizedTarget: normalizedTarget,
    ignorePatterns: ignorePatterns,
  );

  final dir = Directory(p.dirname(resolvedPath));
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return await entity.rename(resolvedPath) as T;
}

Future<void> _deleteIgnoredDestinationIfPresent({
  required String resolvedPath,
  required String normalizedTarget,
  required List<String> ignorePatterns,
}) async {
  final normalizedResolvedPath = p.normalize(p.absolute(resolvedPath));
  if (!_shouldIgnoreEntity(
    normalizedTarget: normalizedTarget,
    normalizedEntityPath: normalizedResolvedPath,
    patterns: ignorePatterns,
  )) {
    return;
  }

  final destination = entityAtPath(resolvedPath);
  if (destination == null) {
    return;
  }

  await _deleteEntityAndPruneParents(
    entity: destination,
    normalizedTarget: normalizedTarget,
  );
}

/// Returns the [FileSystemEntity] at [path], or `null` when it does not exist.
@visibleForTesting
FileSystemEntity? entityAtPath(
  String path, {
  FileSystemEntityType Function(String path)? resolveType,
}) {
  final type = (resolveType ??
      (path) => FileSystemEntity.typeSync(path, followLinks: false))(path);
  return switch (type) {
    FileSystemEntityType.file => File(path),
    FileSystemEntityType.link => Link(path),
    FileSystemEntityType.directory => Directory(path),
    _ => null,
  };
}

Future<void> _resolveTargetFileContents({
  required File file,
  required String targetAbsolutePath,
  required BrickGenConfig config,
}) async {
  final normalizedTarget = p.normalize(p.absolute(targetAbsolutePath));
  final normalizedFilePath = p.normalize(p.absolute(file.path));
  final targetRelativePath = normalizeIgnoreRelativePath(
    p.relative(
      normalizedFilePath,
      from: normalizedTarget,
    ),
  );
  if (shouldSkipContentTransforms(targetRelativePath)) {
    return;
  }

  final content = await readFileTextOrNull(file);
  if (content == null) {
    return;
  }
  final resolvedContent = resolveReferenceContent(
    content: content,
    targetRelativePath: targetRelativePath,
    targetAbsolutePath: normalizedTarget,
    config: config,
  );
  await file.writeAsString(resolvedContent);
}

/// Reads [file] as text, returning `null` when decoding or I/O fails.
@visibleForTesting
Future<String?> readFileTextOrNull(
  File file, {
  Future<String> Function(File file)? readContent,
}) async {
  try {
    return await (readContent ?? (file) => file.readAsString())(file);
  } on FileSystemException {
    return null;
  } on FormatException {
    return null;
  }
}
