import 'package:clay_cli/src/entities/replacement.dart';
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
  final relativePath = p.relative(absolutePath, from: normalizedTarget);
  final resolvedRelativePath = applyReplacements(
    input: relativePath,
    replacements: replacements,
  );

  if (p.isAbsolute(resolvedRelativePath)) {
    throw GenerationException(
      'Path replacement produced an absolute path ($resolvedRelativePath).',
    );
  }

  final resolvedPath = p.normalize(
    p.join(normalizedTarget, resolvedRelativePath),
  );

  if (!p.isWithin(normalizedTarget, resolvedPath)) {
    throw GenerationException(
      'Path replacement would write outside the target directory '
      '($resolvedRelativePath).',
    );
  }

  return resolvedPath;
}
