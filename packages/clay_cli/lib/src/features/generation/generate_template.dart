import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/features/generation/assert_distinct_reference_and_target_paths.dart';
import 'package:clay_cli/src/features/generation/assert_safe_target_path.dart';
import 'package:clay_cli/src/features/generation/copy_directory.dart';
import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:clay_cli/src/features/generation/process_target_file.dart';
import 'package:path/path.dart' as p;

/// Copies [referencePath] to [targetPath] and applies [config] transforms.
///
/// Existing content under [targetPath] is removed before copying. Files
/// matching [BrickGenConfig.ignore] are deleted from the target tree; empty
/// parent directories are pruned. Remaining files receive path renames and
/// content transforms.
Future<void> generateTemplate({
  required BrickGenConfig config,
  required String referencePath,
  required String targetPath,
}) async {
  if (!Directory(referencePath).existsSync()) {
    throw GenerationException(
      'Reference directory not found ($referencePath).',
    );
  }

  assertSafeTargetPath(targetPath: targetPath);
  assertDistinctReferenceAndTargetPaths(
    referencePath: referencePath,
    targetPath: targetPath,
  );

  final normalizedReferencePath = p.normalize(p.absolute(referencePath));
  final normalizedTargetPath = p.normalize(p.absolute(targetPath));
  final referenceDir = Directory(normalizedReferencePath);
  final targetDir = Directory(normalizedTargetPath);
  if (targetDir.existsSync()) {
    await targetDir.delete(recursive: true);
  }

  await copyDirectory(
    source: referenceDir,
    destination: targetDir,
  );

  final targetEntities = targetDir
      .listSync(recursive: true, followLinks: false)
      .where((entity) => entity is File || entity is Link)
      .toList();

  await processCopiedTargetEntities(
    targetEntities: targetEntities,
    normalizedTargetPath: normalizedTargetPath,
    config: config,
  );
}
