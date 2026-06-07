import 'dart:convert';

/// Resolves `insert-start` / `insert-end` blocks in [content].
///
/// Supports C-style, hash, and HTML comment flavors. Lines inside the block
/// must use the matching comment prefix; the prefix is stripped in output.
String applyInsertBlocks({required String content}) {
  const nl = r'(?:\r?\n)';
  final patternGroups = [
    (
      'C-style comment (expected // <content>)',
      [
        r'\/\*insert-start\*\/ *',
        nl,
        '(?<insertion>.*?)',
        nl,
        r' *\/\*insert-end\*\/',
      ].join(),
      r'\/\/ (?<line>.*)',
    ),
    (
      'hash comment (expected # <content>)',
      [
        '#insert-start# *',
        nl,
        '(?<insertion>.*?)',
        nl,
        ' *#insert-end#',
      ].join(),
      '# (?<line>.*)',
    ),
    (
      'HTML comment (expected <!-- <content>-->)',
      [
        '<!--insert-start--> *',
        nl,
        '(?<insertion>.*?)',
        nl,
        ' *<!--insert-end-->',
      ].join(),
      '<!-- (?<line>.*)-->',
    ),
  ];

  return patternGroups.fold(content, (resolved, patternGroup) {
    final (flavorLabel, insertionPattern, linePattern) = patternGroup;
    final insertionRegex = RegExp(insertionPattern, dotAll: true);
    final lineRegex = RegExp(linePattern, dotAll: true);
    return resolved.replaceAllMapped(insertionRegex, (match) {
      match as RegExpMatch;
      final insertion = match.namedGroup('insertion') ?? '';
      final lines = LineSplitter.split(insertion);
      return lines.map((line) {
        final lineMatch = lineRegex.firstMatch(line);
        if (lineMatch == null) {
          throw FormatException(
            'Invalid insert-block line for $flavorLabel: '
            'expected a comment-prefixed line but got "$line".',
          );
        }
        final lineContent = lineMatch.namedGroup('line') ?? '';
        return lineContent;
      }).join('\n');
    });
  });
}
