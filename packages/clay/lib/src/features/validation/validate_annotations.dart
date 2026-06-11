import 'dart:io';

import 'package:clay/clay.dart';
import 'package:clay/src/features/validation/annotation_validator.dart';

/// Recursively validates annotation markers under [referenceDir].
///
/// Returns a list of [AnnotationIssue] values. Each issue formats as
/// `filePath:line:column: message` via [AnnotationIssue.toString].
List<AnnotationIssue> validateAnnotations({required Directory referenceDir}) {
  return AnnotationValidator().validateDirectory(referenceDir);
}
