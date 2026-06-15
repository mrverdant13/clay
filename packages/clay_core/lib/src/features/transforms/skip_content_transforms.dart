import 'package:clay_core/src/utils/binary_content.dart';

/// Whether [targetRelativePath] should bypass the annotation transform
/// pipeline.
bool shouldSkipContentTransforms(String targetRelativePath) {
  return shouldSkipBinaryContent(targetRelativePath);
}
