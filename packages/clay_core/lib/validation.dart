/// Annotation validation.
///
/// Use [validateAnnotations] to scan a reference directory for structural
/// marker issues (unmatched remove/insert/replace/partial blocks, partial name
/// mismatches, nested replace blocks).
///
/// Marker syntax and validation rules:
/// [annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md).
library;

import 'package:clay_core/src/features/validation/validation.dart';

export 'src/features/validation/validate_annotations.dart';
export 'src/features/validation/validation_exception.dart';
