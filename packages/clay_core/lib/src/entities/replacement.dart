import 'package:clay_core/src/utils/regex_hook.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';

part 'replacement.mapper.dart';

/// A regex replacement applied to file paths and contents.
@immutable
@MappableClass()
class Replacement with ReplacementMappable {
  /// Creates a [Replacement].
  const Replacement({required this.from, required this.to});

  /// Creates a [Replacement] from a JSON map.
  // ignore: specify_nonobvious_property_types
  static const fromJson = ReplacementMapper.fromMap;

  /// The pattern to match.
  @MappableField(hook: regexHook)
  final RegExp from;

  /// The replacement string; supports `${n}` capture-group interpolation.
  final String to;
}
