import 'dart:io';

import 'package:clay_cli/src/features/config/discover_brick_gen_config.dart';
import 'package:clay_cli/src/features/config/load_brick_gen_config.dart';
import 'package:clay_cli/src/features/config/resolve_paths.dart';
import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:clay_cli/src/features/generation/resolve_target_file_path.dart';
import 'package:clay_cli/src/features/preview/preview_exception.dart';
import 'package:clay_cli/src/features/transforms/resolve_reference_content.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Outcome of a successful preview run.
class PreviewRunResult {
  /// Creates a [PreviewRunResult].
  const PreviewRunResult({
    required this.configPath,
    required this.projectRoot,
    required this.referencePath,
    required this.targetPath,
    required this.filePath,
    required this.content,
  });

  /// Absolute path to the resolved `brick-gen.json` file.
  final String configPath;

  /// Absolute path to the project root.
  final String projectRoot;

  /// Absolute path to the reference directory.
  final String referencePath;

  /// Absolute path to the target directory.
  final String targetPath;

  /// Absolute path to the previewed reference file.
  final String filePath;

  /// Transformed file content.
  final String content;
}

/// Discovers config, resolves paths, and previews a single reference file.
Future<PreviewRunResult> runPreview({
  required String filePath,
  required bool templateOnly,
  Map<String, dynamic> vars = const {},
  String? configPath,
  String? cwd,
  String? referenceOverride,
  String? targetOverride,
}) async {
  final discovered = discoverBrickGenConfig(
    configPath: configPath,
    cwd: cwd,
  );
  final config = await loadBrickGenConfig(
    configPath: discovered.configPath,
  );
  final referencePath = resolveReferencePath(
    projectRoot: discovered.projectRoot,
    config: config,
    cliOverride: referenceOverride,
  );
  final targetPath = resolveTargetPath(
    projectRoot: discovered.projectRoot,
    config: config,
    cliOverride: targetOverride,
  );

  final referenceDir = Directory(referencePath);
  if (!referenceDir.existsSync()) {
    throw PreviewException(
      'Reference directory not found ($referencePath).',
    );
  }

  final resolvedFilePath = resolveReferenceFilePath(
    filePath: filePath,
    referencePath: referencePath,
  );
  assertPreviewPathIsFile(resolvedFilePath);

  final file = File(resolvedFilePath);

  final tempTargetDir = await Directory.systemTemp.createTemp('clay_preview_');
  try {
    final referenceRelativePath = p.relative(
      resolvedFilePath,
      from: referenceDir.path,
    );
    final simulatedTargetPath = p.join(
      tempTargetDir.path,
      referenceRelativePath,
    );
    final resolvedTargetPath = resolveTargetFilePath(
      absolutePath: simulatedTargetPath,
      targetAbsolutePath: tempTargetDir.path,
      replacements: config.replacements,
    );
    final targetRelativePath = p.relative(
      resolvedTargetPath,
      from: tempTargetDir.path,
    );

    final annotatedContent = resolveReferenceContent(
      content: await file.readAsString(),
      targetRelativePath: targetRelativePath,
      targetAbsolutePath: tempTargetDir.path,
      config: config,
    );

    final content = templateOnly
        ? annotatedContent
        : annotatedContent.render(
            vars,
            loadPreviewPartials(tempTargetDir),
          );

    return PreviewRunResult(
      configPath: discovered.configPath,
      projectRoot: discovered.projectRoot,
      referencePath: p.normalize(p.absolute(referencePath)),
      targetPath: p.normalize(p.absolute(targetPath)),
      filePath: p.normalize(p.absolute(resolvedFilePath)),
      content: content,
    );
  } on GenerationException catch (error) {
    throw PreviewException(error.message);
  } finally {
    if (tempTargetDir.existsSync()) {
      await tempTargetDir.delete(recursive: true);
    }
  }
}

/// Throws when [resolvedFilePath] does not refer to a readable file.
@visibleForTesting
void assertPreviewPathIsFile(
  String resolvedFilePath, {
  FileSystemEntityType Function(String path)? resolveEntityType,
}) {
  final entityType = (resolveEntityType ??
      (path) => FileSystemEntity.typeSync(path, followLinks: false))(
    resolvedFilePath,
  );
  switch (entityType) {
    case FileSystemEntityType.file:
      return;
    case FileSystemEntityType.notFound:
      throw PreviewException('File not found: $resolvedFilePath');
    case FileSystemEntityType.directory:
    case FileSystemEntityType.link:
    case FileSystemEntityType.pipe:
    case FileSystemEntityType.unixDomainSock:
      throw PreviewException('Path is not a file: $resolvedFilePath');
  }
}

/// Resolves [filePath] to an absolute path under [referencePath].
@visibleForTesting
String resolveReferenceFilePath({
  required String filePath,
  required String referencePath,
}) {
  final normalizedReference = p.normalize(p.absolute(referencePath));
  final resolved = p.isAbsolute(filePath)
      ? p.normalize(filePath)
      : p.normalize(p.join(normalizedReference, filePath));

  if (!p.isWithin(normalizedReference, resolved)) {
    throw PreviewException(
      'File must be under the reference directory ($normalizedReference).',
    );
  }

  return resolved;
}

/// Loads partial files created during annotation resolution.
@visibleForTesting
Map<String, List<int>> loadPreviewPartials(Directory targetDir) {
  if (!targetDir.existsSync()) {
    return {};
  }

  final partials = <String, List<int>>{};
  for (final entity
      in targetDir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }

    final name = p.basename(entity.path);
    if (!name.startsWith('{{~ ') || !name.endsWith(' }}')) {
      continue;
    }

    partials[name] = entity.readAsBytesSync();
  }

  return partials;
}
