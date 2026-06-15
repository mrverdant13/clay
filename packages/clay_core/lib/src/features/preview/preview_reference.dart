import 'dart:io';

import 'package:clay_core/src/entities/clay_config.dart';
import 'package:clay_core/src/features/generation/generation_exception.dart';
import 'package:clay_core/src/features/generation/resolve_target_file_path.dart';
import 'package:clay_core/src/features/preview/preview_exception.dart';
import 'package:clay_core/src/features/transforms/resolve_reference_content.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Transforms [filePath] under [referencePath] and optionally renders Mason
/// vars.
///
/// When [templateOnly] is true, Mustache tags remain in the output.
Future<String> previewReferenceFile({
  required String filePath,
  required String referencePath,
  required ClayConfig config,
  required bool templateOnly,
  Map<String, dynamic> vars = const {},
}) async {
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

    return templateOnly
        ? annotatedContent
        : annotatedContent.render(
            vars,
            loadPreviewPartials(tempTargetDir),
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
