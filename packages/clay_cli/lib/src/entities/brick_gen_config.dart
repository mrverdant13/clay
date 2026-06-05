import 'package:clay_cli/src/entities/line_deletion.dart';
import 'package:clay_cli/src/entities/replacement.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';

part 'brick_gen_config.mapper.dart';

/// Default [BrickGenConfig.reference] when omitted from `brick-gen.json`.
const defaultReferencePath = 'reference';

/// Default [BrickGenConfig.target] when omitted from `brick-gen.json`.
const defaultTargetPath = 'brick/__brick__';

/// Parsed `brick-gen.json` configuration.
@immutable
@MappableClass()
class BrickGenConfig with BrickGenConfigMappable {
  /// Creates a [BrickGenConfig].
  const BrickGenConfig({
    this.reference = defaultReferencePath,
    this.target = defaultTargetPath,
    this.ignore = const [],
    this.replacements = const [],
    this.lineDeletions = const [],
  });

  /// Creates a [BrickGenConfig] from a JSON map.
  // ignore: specify_nonobvious_property_types
  static const fromJson = BrickGenConfigMapper.fromMap;

  /// Path to the reference project root.
  final String reference;

  /// Path to the template output root.
  final String target;

  /// Gitignore-style glob patterns excluded from template output.
  final List<String> ignore;

  /// Regex replacements applied to file paths and contents.
  final List<Replacement> replacements;

  /// Line ranges removed from specific target files.
  final List<LineDeletion> lineDeletions;
}
