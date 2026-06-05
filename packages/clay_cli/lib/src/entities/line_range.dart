import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';

part 'line_range.mapper.dart';

/// An inclusive, zero-based line range within a target file.
@immutable
@MappableClass()
class LineRange with LineRangeMappable {
  /// Creates a [LineRange].
  const LineRange({required this.start, required this.end});

  /// Creates a [LineRange] from a JSON map.
  // ignore: specify_nonobvious_property_types
  static const fromJson = LineRangeMapper.fromMap;

  /// The beginning of the range (inclusive and zero-based).
  final int start;

  /// The end of the range (inclusive and zero-based).
  final int end;

  /// Whether [lineNumber] falls within this range.
  bool contains(int lineNumber) => start <= lineNumber && lineNumber <= end;
}
