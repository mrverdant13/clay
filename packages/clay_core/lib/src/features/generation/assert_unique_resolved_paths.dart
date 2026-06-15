import 'package:clay_core/src/entities/entities.dart';
import 'package:clay_core/src/features/config/matches_ignore_pattern.dart';
import 'package:clay_core/src/features/generation/generation_exception.dart';
import 'package:clay_core/src/features/generation/resolve_target_file_path.dart';
import 'package:path/path.dart' as p;

/// Registers [entityPath] in [resolvedPaths] or throws on collision.
void registerResolvedPath({
  required Map<String, String> resolvedPaths,
  required String entityPath,
  required String targetAbsolutePath,
  required ClayConfig config,
}) {
  final normalizedTarget = p.normalize(p.absolute(targetAbsolutePath));
  final normalizedEntityPath = p.normalize(p.absolute(entityPath));
  if (shouldIgnoreAtRoot(
    rootDirectory: normalizedTarget,
    absolutePath: normalizedEntityPath,
    patterns: config.ignore,
  )) {
    return;
  }

  final resolvedPath = resolveTargetFilePath(
    absolutePath: normalizedEntityPath,
    targetAbsolutePath: normalizedTarget,
    replacements: config.replacements,
  );

  final existingSource = resolvedPaths[resolvedPath];
  if (existingSource != null &&
      !p.equals(existingSource, normalizedEntityPath)) {
    throw GenerationException(
      'Path replacement collision: $existingSource and '
      '$normalizedEntityPath both map to $resolvedPath.',
    );
  }
  resolvedPaths[resolvedPath] = normalizedEntityPath;
}

/// Ensures path replacements do not map multiple entries to the same output.
void assertUniqueResolvedPaths({
  required Iterable<String> entityPaths,
  required String targetAbsolutePath,
  required ClayConfig config,
}) {
  final resolvedPaths = <String, String>{};
  for (final entityPath in entityPaths) {
    registerResolvedPath(
      resolvedPaths: resolvedPaths,
      entityPath: entityPath,
      targetAbsolutePath: targetAbsolutePath,
      config: config,
    );
  }
}
