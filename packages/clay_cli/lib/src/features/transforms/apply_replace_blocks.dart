import 'dart:convert';

/// Resolves `replace-start` / `with` / `replace-end` blocks in [content].
///
/// Supports C-style, hash, and HTML comment flavors. Optional `i<N>` on the
/// `with` marker indents each replacement line by N spaces.
String applyReplaceBlocks({required String content}) {
  const nl = r'(?:\r?\n)';
  final patternGroups = [
    (
      [
        r'\/\*replace-start\*\/ *',
        nl,
        '*.*?',
        nl,
        r'* *\/\*with(?: +i(?<indentation>\d+))?\*\/ *',
        nl,
        '(?<replacement>.*?)',
        nl,
        r' *\/\*replace-end\*\/',
      ].join(),
      r'\/\/ (?<line>.*)',
    ),
    (
      [
        '#replace-start# *',
        nl,
        '*.*?',
        nl,
        r'* *#with(?: +i(?<indentation>\d+))?# *',
        nl,
        '(?<replacement>.*?)',
        nl,
        ' *#replace-end#',
      ].join(),
      '# (?<line>.*)',
    ),
    (
      [
        '<!--replace-start--> *',
        nl,
        '*.*?',
        nl,
        r'* *<!--with(?: +i(?<indentation>\d+))?--> *',
        nl,
        '(?<replacement>.*?)',
        nl,
        ' *<!--replace-end-->',
      ].join(),
      '<!-- (?<line>.*)-->',
    ),
  ];

  return patternGroups.fold(content, (resolved, patternGroup) {
    final (replacementPattern, linePattern) = patternGroup;
    final replacementRegex = RegExp(replacementPattern, dotAll: true);
    final lineRegex = RegExp(linePattern, dotAll: true);
    return resolved.replaceAllMapped(replacementRegex, (match) {
      match as RegExpMatch;
      final indentation =
          int.tryParse(match.namedGroup('indentation') ?? '') ?? 0;
      final replacement = match.namedGroup('replacement') ?? '';
      final lines = LineSplitter.split(replacement);
      return lines.map((line) {
        final lineMatch = lineRegex.allMatches(line).single;
        final lineContent = lineMatch.namedGroup('line') ?? '';
        return ' ' * indentation + lineContent;
      }).join('\n');
    });
  });
}
