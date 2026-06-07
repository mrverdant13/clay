import 'package:clay_cli/src/entities/replacement.dart';
import 'package:clay_cli/src/features/transforms/apply_replacements.dart';
import 'package:path/path.dart' as p;

/// Applies [replacements] to the target-relative path of [absolutePath].
String resolveTargetFilePath({
  required String absolutePath,
  required String targetAbsolutePath,
  required List<Replacement> replacements,
}) {
  final relativePath = p.relative(absolutePath, from: targetAbsolutePath);
  final resolvedRelativePath = applyReplacements(
    input: relativePath,
    replacements: replacements,
  );
  return p.normalize(p.join(targetAbsolutePath, resolvedRelativePath));
}
