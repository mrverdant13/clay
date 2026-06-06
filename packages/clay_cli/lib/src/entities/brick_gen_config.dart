import 'package:clay_cli/src/entities/line_deletion.dart';
import 'package:clay_cli/src/entities/replacement.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

part 'brick_gen_config.mapper.dart';

/// Parsed `brick-gen.json` configuration.
@immutable
@MappableClass()
class BrickGenConfig with BrickGenConfigMappable {
  /// Creates a [BrickGenConfig].
  BrickGenConfig({
    this.reference = BrickGenConfig.defaultReferencePath,
    this.ignore = const [],
    this.replacements = const [],
    this.lineDeletions = const [],
    String? target,
  }) : target = target ?? BrickGenConfig.defaultTargetPath;

  /// Creates a [BrickGenConfig] from a JSON map.
  // ignore: specify_nonobvious_property_types
  static const fromJson = BrickGenConfigMapper.fromMap;

  /// Default [BrickGenConfig.reference] when omitted.
  static const defaultReferencePath = 'reference';

  /// Default [BrickGenConfig.target] when omitted.
  static final String defaultTargetPath = p.join('brick', '__brick__');

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
