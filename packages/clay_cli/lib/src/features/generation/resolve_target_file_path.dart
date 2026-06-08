import 'package:clay_cli/src/entities/replacement.dart';
import 'package:clay_cli/src/features/config/matches_ignore_pattern.dart';
import 'package:clay_cli/src/features/generation/generation_exception.dart';
import 'package:clay_cli/src/features/transforms/apply_replacements.dart';
import 'package:path/path.dart' as p;

/// Applies [replacements] to the target-relative path of [absolutePath].
String resolveTargetFilePath({
  required String absolutePath,
  required String targetAbsolutePath,
  required List<Replacement> replacements,
}) {
  final normalizedTarget = p.normalize(p.absolute(targetAbsolutePath));
  final normalizedAbsolutePath = p.normalize(p.absolute(absolutePath));
  final relativePath = normalizeIgnoreRelativePath(
    p.relative(
      normalizedAbsolutePath,
      from: normalizedTarget,
    ),
  );
  final resolvedRelativePath = applyFirstPathReplacement(
    input: relativePath,
    replacements: replacements,
  );

  if (p.posix.isAbsolute(resolvedRelativePath)) {
    throw GenerationException(
      'Path replacement produced an absolute path ($resolvedRelativePath).',
    );
  }

  final resolvedPath = p.normalize(
    p.join(
      normalizedTarget,
      resolvedRelativePath.replaceAll('/', p.separator),
    ),
  );

  if (!p.isWithin(normalizedTarget, resolvedPath)) {
    throw GenerationException(
      'Path replacement would write outside the target directory '
      '($resolvedRelativePath).',
    );
  }

  return resolvedPath;
}
