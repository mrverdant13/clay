import 'dart:io';

import 'package:clay_core/src/entities/entities.dart';
import 'package:clay_core/src/features/validation/annotation_validator.dart';

/// Recursively validates annotation markers under [referenceDir].
///
/// Checks remove, insert, replace, and partial block pairing. Drop markers,
/// Mustache unwrap comments, and spacing groups are not structurally validated.
///
/// Marker syntax and error messages:
/// [annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md).
///
/// Returns a list of [AnnotationIssue] values. Each issue formats as
/// `filePath:line:column: message` via [AnnotationIssue.toString].
List<AnnotationIssue> validateAnnotations({required Directory referenceDir}) {
  return AnnotationValidator().validateDirectory(referenceDir);
}
