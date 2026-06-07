import 'package:path/path.dart' as p;

/// Extensions that are copied to output but not text-transformed.
const _binaryContentExtensions = {'.png', '.webp'};

/// Whether [targetRelativePath] should bypass the annotation transform
/// pipeline.
bool shouldSkipContentTransforms(String targetRelativePath) {
  return _binaryContentExtensions.contains(
    p.extension(targetRelativePath).toLowerCase(),
  );
}
