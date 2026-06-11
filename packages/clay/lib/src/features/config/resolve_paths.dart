import 'package:clay/src/entities/brick_gen_config.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Resolves [path] relative to [projectRoot], or returns the normalized [path]
/// when it is absolute.
@visibleForTesting
String resolvePathFromProjectRoot({
  required String projectRoot,
  required String path,
}) {
  if (p.isAbsolute(path)) {
    return p.normalize(path);
  }
  return p.normalize(p.join(projectRoot, path));
}

/// Resolves the reference directory path.
///
/// Priority: [cliOverride] → [config] ([BrickGenConfig.reference]) → built-in
/// default.
String resolveReferencePath({
  required String projectRoot,
  required BrickGenConfig config,
  String? cliOverride,
}) {
  final path = cliOverride ?? config.reference;
  return resolvePathFromProjectRoot(projectRoot: projectRoot, path: path);
}

/// Resolves the target directory path.
///
/// Priority: [cliOverride] → [config] ([BrickGenConfig.target]) → built-in
/// default.
String resolveTargetPath({
  required String projectRoot,
  required BrickGenConfig config,
  String? cliOverride,
}) {
  final path = cliOverride ?? config.target;
  return resolvePathFromProjectRoot(projectRoot: projectRoot, path: path);
}
