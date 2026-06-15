import 'dart:io';

import 'package:clay_core/clay.dart' show AnnotationIssue, ClayConfig;
import 'package:clay_core/config.dart';
import 'package:clay_core/generation.dart';
import 'package:clay_core/preview.dart';
import 'package:clay_core/validation.dart';
import 'package:path/path.dart' as p;

/// Resolved Clay project paths for library E2E runs.
class ResolvedClayProject {
  /// Creates a [ResolvedClayProject].
  const ResolvedClayProject({
    required this.configPath,
    required this.projectRoot,
    required this.config,
    required this.referencePath,
    required this.targetPath,
  });

  /// Absolute path to the resolved config file.
  final String configPath;

  /// Absolute path to the project root.
  final String projectRoot;

  /// Parsed project configuration.
  final ClayConfig config;

  /// Absolute path to the reference directory.
  final String referencePath;

  /// Absolute path to the target directory.
  final String targetPath;
}

/// Discovers and loads the Clay project at [cwd].
Future<ResolvedClayProject> resolveClayProject({required String cwd}) async {
  final discovered = discoverClayConfig(cwd: cwd);
  final config = await loadClayConfig(configPath: discovered.configPath);
  final referencePath = resolveReferencePath(
    projectRoot: discovered.projectRoot,
    config: config,
  );
  final targetPath = resolveTargetPath(
    projectRoot: discovered.projectRoot,
    config: config,
  );

  return ResolvedClayProject(
    configPath: discovered.configPath,
    projectRoot: discovered.projectRoot,
    config: config,
    referencePath: referencePath,
    targetPath: targetPath,
  );
}

/// Generates the template tree for the project at [cwd].
Future<void> runClayGenerate({required String cwd}) async {
  final project = await resolveClayProject(cwd: cwd);
  await generateTemplate(
    config: project.config,
    referencePath: project.referencePath,
    targetPath: project.targetPath,
  );
}

/// Counts files and symlinks under [targetPath].
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

/// Validates annotation markers under the reference directory at [cwd].
Future<List<AnnotationIssue>> runClayValidate({required String cwd}) async {
  final project = await resolveClayProject(cwd: cwd);
  final referenceDir = Directory(project.referencePath);
  if (!referenceDir.existsSync()) {
    throw StateError(
      'Reference directory not found (${project.referencePath}).',
    );
  }

  return validateAnnotations(referenceDir: referenceDir);
}

/// Previews a single reference file via the public library API.
Future<String> runClayPreview({
  required String cwd,
  required String filePath,
  required bool templateOnly,
  Map<String, dynamic> vars = const {},
}) async {
  final project = await resolveClayProject(cwd: cwd);
  return previewReferenceFile(
    filePath: filePath,
    referencePath: project.referencePath,
    config: project.config,
    templateOnly: templateOnly,
    vars: vars,
  );
}

/// Normalizes [path] for stable assertions in E2E tests.
String normalizeE2ePath(String path) => p.normalize(p.absolute(path));
