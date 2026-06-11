import 'dart:io';

import 'package:clay/clay.dart' show AnnotationIssue;
import 'package:clay/config.dart' show resolveReferencePath;
import 'package:clay/validation.dart';
import 'package:clay_cli/src/run/resolve_project_config.dart';
import 'package:path/path.dart' as p;

/// Outcome of a successful annotation validation run.
class ValidateRunResult {
  /// Creates a [ValidateRunResult].
  const ValidateRunResult({
    required this.configPath,
    required this.projectRoot,
    required this.referencePath,
    required this.issues,
  });

  /// Absolute path to the resolved config file.
  final String configPath;

  /// Absolute path to the project root.
  final String projectRoot;

  /// Absolute path to the reference directory.
  final String referencePath;

  /// Annotation issues found under [referencePath].
  final List<AnnotationIssue> issues;
}

/// Exit code returned when validation finds one or more issues.
const validationIssuesExitCode = 1;

/// Discovers config, resolves the reference path, and validates annotations.
Future<ValidateRunResult> runValidate({
  String? configPath,
  String? cwd,
  String? referenceOverride,
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
  final referenceDir = Directory(referencePath);
  if (!referenceDir.existsSync()) {
    throw ValidationException(
      'Reference directory not found ($referencePath).',
    );
  }

  final issues = validateAnnotations(referenceDir: referenceDir);

  return ValidateRunResult(
    configPath: resolved.configPath,
    projectRoot: resolved.projectRoot,
    referencePath: p.normalize(p.absolute(referencePath)),
    issues: List.unmodifiable(issues),
  );
}

/// Formats [issues] as stderr lines.
List<String> formatValidateIssues(List<AnnotationIssue> issues) =>
    issues.map((issue) => issue.toString()).toList();
