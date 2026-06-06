import 'dart:convert';

import 'package:clay_cli/src/entities/line_deletion.dart';
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
  final applyableDeletions = lineDeletions.where(
    (deletion) => path.equals(deletion.filePath, filePath),
  );
  final deletableRanges = applyableDeletions.expand(
    (deletion) => deletion.ranges,
  );
  if (deletableRanges.isEmpty) {
    return content;
  }

  final buffer = StringBuffer();
  for (final (lineIndex, lineContent) in lines.indexed) {
    final shouldBeDropped = deletableRanges.any(
      (range) => range.contains(lineIndex),
    );
    if (!shouldBeDropped) {
      buffer.writeln(lineContent);
    }
  }
  return buffer.toString();
}
