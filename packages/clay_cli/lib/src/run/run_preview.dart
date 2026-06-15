import 'package:clay_cli/src/run/resolve_project_config.dart';
import 'package:clay_core/config.dart'
    show resolveReferencePath, resolveTargetPath;
import 'package:clay_core/preview.dart';
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

  /// Absolute path to the resolved config file.
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

  final content = await previewReferenceFile(
    filePath: filePath,
    referencePath: referencePath,
    config: resolved.config,
    templateOnly: templateOnly,
    vars: vars,
  );

  final normalizedReference = p.normalize(p.absolute(referencePath));
  final resolvedFilePath = p.isAbsolute(filePath)
      ? p.normalize(filePath)
      : p.normalize(p.join(normalizedReference, filePath));

  return PreviewRunResult(
    configPath: resolved.configPath,
    projectRoot: resolved.projectRoot,
    referencePath: normalizedReference,
    targetPath: p.normalize(p.absolute(targetPath)),
    filePath: resolvedFilePath,
    content: content,
  );
}
