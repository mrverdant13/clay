import 'package:clay/clay.dart';

/// Whether [targetRelativePath] should bypass the annotation transform
/// pipeline.
bool shouldSkipContentTransforms(String targetRelativePath) {
  return shouldSkipBinaryContent(targetRelativePath);
}
