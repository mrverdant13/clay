/// Programmatic APIs for loading config, transforming reference content,
/// generating templates, and validating annotations.
library;

export 'package:clay/clay.dart' show AnnotationIssue, BrickGenConfig;
export 'src/clay_cli.dart';
export 'src/commands/commands.dart';
export 'src/features/config/load_brick_gen_config.dart';
export 'src/features/generation/generate_template.dart';
export 'src/features/transforms/resolve_reference_content.dart';
export 'src/features/validation/validate_annotations.dart';
