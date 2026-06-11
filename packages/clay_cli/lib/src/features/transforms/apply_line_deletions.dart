import 'dart:convert';

import 'package:clay/clay.dart';
import 'package:path/path.dart' as path;

/// Drops configured line ranges from [content] when [filePath] matches.
///
/// [filePath] is relative to the target directory root. [lineDeletions] ranges
/// use zero-based, inclusive line indices.
String applyLineDeletions({
  required String content,
  required String filePath,
  required List<LineDeletion> lineDeletions,
}) {
  final lines = LineSplitter.split(content);
  final applicableRanges = lineDeletions
      .where((deletion) => path.equals(deletion.filePath, filePath))
      .expand((deletion) => deletion.ranges)
      .toList();
  if (applicableRanges.isEmpty) {
    return content;
  }

  final buffer = StringBuffer();
  for (final (lineIndex, lineContent) in lines.indexed) {
    final shouldBeDropped = applicableRanges.any(
      (range) => range.contains(lineIndex),
    );
    if (!shouldBeDropped) {
      buffer.writeln(lineContent);
    }
  }
  return buffer.toString();
}
