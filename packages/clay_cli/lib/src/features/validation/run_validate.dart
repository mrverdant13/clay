import 'dart:io';

import 'package:clay_cli/src/entities/annotation_issue.dart';
import 'package:clay_cli/src/features/config/discover_brick_gen_config.dart';
import 'package:clay_cli/src/features/config/load_brick_gen_config.dart';
import 'package:clay_cli/src/features/config/resolve_paths.dart';
import 'package:clay_cli/src/features/validation/validate_annotations.dart';
import 'package:clay_cli/src/features/validation/validation_exception.dart';
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

  /// Absolute path to the resolved `brick-gen.json` file.
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
  final referenceDir = Directory(referencePath);
  if (!referenceDir.existsSync()) {
    throw ValidationException(
      'Reference directory not found ($referencePath).',
    );
  }

  final issues = validateAnnotations(referenceDir: referenceDir);

  return ValidateRunResult(
    configPath: discovered.configPath,
    projectRoot: discovered.projectRoot,
    referencePath: p.normalize(p.absolute(referencePath)),
    issues: List.unmodifiable(issues),
  );
}

/// Formats [issues] as stderr lines.
List<String> formatValidateIssues(List<AnnotationIssue> issues) =>
    issues.map((issue) => issue.toString()).toList();
