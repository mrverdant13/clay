import 'package:clay_cli/src/entities/line_range.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';

part 'line_deletion.mapper.dart';

/// Line ranges to drop from a specific target file.
@immutable
@MappableClass()
class LineDeletion with LineDeletionMappable {
  /// Creates a [LineDeletion].
  const LineDeletion({required this.filePath, required this.ranges});

  /// Creates a [LineDeletion] from a JSON map.
  // ignore: specify_nonobvious_property_types
  static const fromJson = LineDeletionMapper.fromMap;

  /// Path to the target file, relative to the target directory root.
  final String filePath;

  /// Ranges of lines to remove from [filePath].
  final List<LineRange> ranges;
}
