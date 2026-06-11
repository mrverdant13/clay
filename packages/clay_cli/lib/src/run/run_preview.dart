import 'package:clay/clay.dart';
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

  final content = await previewReferenceFile(
    filePath: filePath,
    referencePath: referencePath,
    config: config,
    templateOnly: templateOnly,
    vars: vars,
  );

  final normalizedReference = p.normalize(p.absolute(referencePath));
  final resolvedFilePath = p.isAbsolute(filePath)
      ? p.normalize(filePath)
      : p.normalize(p.join(normalizedReference, filePath));

  return PreviewRunResult(
    configPath: discovered.configPath,
    projectRoot: discovered.projectRoot,
    referencePath: normalizedReference,
    targetPath: p.normalize(p.absolute(targetPath)),
    filePath: resolvedFilePath,
    content: content,
  );
}
