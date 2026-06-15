import 'dart:io';

import 'package:clay_cli/src/run/resolve_project_config.dart';
import 'package:clay_core/config.dart'
    show resolveReferencePath, resolveTargetPath;
import 'package:clay_core/generation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Outcome of a successful template generation run.
class GenRunResult {
  /// Creates a [GenRunResult].
  const GenRunResult({
    required this.configPath,
    required this.projectRoot,
    required this.referencePath,
    required this.targetPath,
    required this.fileCount,
    required this.excludedFiles,
  });

  /// Absolute path to the resolved config file.
  final String configPath;

  /// Absolute path to the project root.
  final String projectRoot;

  /// Absolute path to the reference directory.
  final String referencePath;

  /// Absolute path to the target directory.
  final String targetPath;

  /// Number of files remaining in the target tree after generation.
  final int fileCount;

  /// Target-relative paths excluded by `ignore` patterns.
  final List<String> excludedFiles;
}

/// Discovers config, resolves paths, and generates the template.
Future<GenRunResult> runGen({
  String? configPath,
  String? cwd,
  String? referenceOverride,
  String? targetOverride,
  void Function(String relativePath)? onIgnoredFile,
}) async {
  final resolved = await resolveProjectConfig(
    configPath: configPath,
    cwd: cwd,
  );
  final referencePath = resolveReferencePath(
    projectRoot: resolved.projectRoot,
    config: resolved.config,
    cliOverride: referenceOverride,
  );
  final targetPath = resolveTargetPath(
    projectRoot: resolved.projectRoot,
    config: resolved.config,
    cliOverride: targetOverride,
  );

  final excludedFiles = <String>[];
  await generateTemplate(
    config: resolved.config,
    referencePath: referencePath,
    targetPath: targetPath,
    onIgnoredFile: (relativePath) {
      onIgnoredFile?.call(relativePath);
      excludedFiles.add(relativePath);
    },
  );

  return GenRunResult(
    configPath: resolved.configPath,
    projectRoot: resolved.projectRoot,
    referencePath: p.normalize(p.absolute(referencePath)),
    targetPath: p.normalize(p.absolute(targetPath)),
    fileCount: countTargetFiles(targetPath),
    excludedFiles: List.unmodifiable(excludedFiles),
  );
}

/// Counts files and symlinks under [targetPath].
@visibleForTesting
int countTargetFiles(String targetPath) {
  final dir = Directory(targetPath);
  if (!dir.existsSync()) {
    return 0;
  }

  return dir
      .listSync(recursive: true, followLinks: false)
      .where((entity) => entity is File || entity is Link)
      .length;
}

/// Formats [result] as stdout lines after generation.
List<String> formatGenRunSummary(GenRunResult result) => [
      'Reference: ${result.referencePath}',
      'Target: ${result.targetPath}',
      'Files: ${result.fileCount}',
    ];
