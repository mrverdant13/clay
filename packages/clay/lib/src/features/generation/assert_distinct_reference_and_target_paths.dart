import 'package:clay/src/features/generation/generation_exception.dart';
import 'package:path/path.dart' as p;

/// Ensures [referencePath] and [targetPath] do not overlap.
///
/// Throws [GenerationException] when the paths are equal or one is nested
/// inside the other.
void assertDistinctReferenceAndTargetPaths({
  required String referencePath,
  required String targetPath,
}) {
  final normalizedReference = p.normalize(p.absolute(referencePath));
  final normalizedTarget = p.normalize(p.absolute(targetPath));

  if (normalizedReference == normalizedTarget) {
    throw GenerationException(
      'Reference and target paths must differ ($referencePath).',
    );
  }

  if (p.isWithin(normalizedReference, normalizedTarget)) {
    throw GenerationException(
      'Target path cannot be inside the reference directory '
      '($targetPath).',
    );
  }

  if (p.isWithin(normalizedTarget, normalizedReference)) {
    throw GenerationException(
      'Reference path cannot be inside the target directory '
      '($referencePath).',
    );
  }
}
