import 'dart:io';

import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/features/generation/assert_distinct_reference_and_target_paths.dart';
import 'package:clay_cli/src/features/generation/copy_directory.dart';
import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:clay_cli/src/features/generation/process_target_file.dart';

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
  final referenceDir = Directory(referencePath);
  if (!referenceDir.existsSync()) {
    throw GenerationException(
      'Reference directory not found ($referencePath).',
    );
  }

  assertDistinctReferenceAndTargetPaths(
    referencePath: referencePath,
    targetPath: targetPath,
  );

  final targetDir = Directory(targetPath);
  if (targetDir.existsSync()) {
    await targetDir.delete(recursive: true);
  }

  await copyDirectory(
    source: referenceDir,
    destination: targetDir,
  );

  final files = targetDir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .toList();

  await Future.wait<void>([
    for (final file in files)
      processTargetFile(
        file: file,
        targetAbsolutePath: targetPath,
        config: config,
      ),
  ]);
}
