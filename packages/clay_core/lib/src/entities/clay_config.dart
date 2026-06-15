import 'package:clay_core/src/entities/line_deletion.dart';
import 'package:clay_core/src/entities/replacement.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

part 'clay_config.mapper.dart';

/// Parsed `clay.yaml` configuration.
@immutable
@MappableClass()
class ClayConfig with ClayConfigMappable {
  /// Creates a [ClayConfig].
  ClayConfig({
    this.reference = ClayConfig.defaultReferencePath,
    this.ignore = const [],
    this.replacements = const [],
    this.lineDeletions = const [],
    String? target,
  }) : target = target ?? ClayConfig.defaultTargetPath;

  /// Creates a [ClayConfig] from a config map.
  // ignore: specify_nonobvious_property_types
  static const fromMap = ClayConfigMapper.fromMap;

  /// Default [ClayConfig.reference] when omitted.
  static const defaultReferencePath = 'reference';

  /// Default [ClayConfig.target] when omitted.
  static final String defaultTargetPath = p.join('brick', '__brick__');

  /// Path to the reference project root.
  final String reference;

  /// Path to the template output root.
  final String target;

  /// Gitignore-style glob patterns excluded from template output.
  ///
  /// Patterns must use POSIX-style forward slashes and are relative to the
  /// reference or target root. A leading `/` anchors to that root;
  /// Windows-absolute paths are rejected at load time.
  final List<String> ignore;

  /// Regex replacements applied to file paths and contents.
  final List<Replacement> replacements;

  /// Line ranges removed from specific target files.
  final List<LineDeletion> lineDeletions;
}
