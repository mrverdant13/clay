/// Reference content transform pipeline.
///
/// The main entry point is [resolveReferenceContent], which applies
/// `clay.yaml` line deletions and regex replacements, then annotation markers
/// (remove, replace, insert, Mustache unwrap, spacing groups, partials) in a
/// fixed order.
///
/// Marker syntax is documented in the
/// [annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md).
library;

import 'package:clay_core/src/features/transforms/transforms.dart';

export 'src/features/transforms/resolve_reference_content.dart';
