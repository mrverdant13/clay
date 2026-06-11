/// Resolves `drop` markers and `remove-start` / `remove-end` blocks in [content].
///
/// Supports C-style, hash, and HTML comment flavors. Optional `x-` / `-x` flags
/// control whether leading or trailing whitespace adjacent to a remove block
/// is retained.
String applyRemotions({required String content}) {
  final blockDropPatterns = [
    r'\/\*drop\*\/.*',
    '#drop#.*',
    '<!--drop-->.*',
  ];
  final blockDropPattern =
      blockDropPatterns.map((pattern) => '(?:$pattern)').join('|');
  final blockDropRegex = RegExp(blockDropPattern, dotAll: true);
  final afterDropContent = content.replaceAll(blockDropRegex, '');

  const blockRemotionPatterns = [
    r'(?<leading>\s*)\/\*(?<dropLeading>x-)?remove-start\*\/.*?\/\*remove-end(?<dropTrailing>-x)?\*\/(?<trailing>\s*)',
    r'(?<leading>\s*)#(?<dropLeading>x-)?remove-start#.*?#remove-end(?<dropTrailing>-x)?#(?<trailing>\s*)',
    r'(?<leading>\s*)<!--(?<dropLeading>x-)?remove-start-->.*?<!--remove-end(?<dropTrailing>-x)?-->(?<trailing>\s*)',
  ];

  return blockRemotionPatterns.fold(afterDropContent, (resolved, pattern) {
    final regex = RegExp(pattern, dotAll: true);
    return resolved.replaceAllMapped(regex, (match) {
      match as RegExpMatch;
      final keepLeading = (match.namedGroup('dropLeading') ?? '').isEmpty;
      final keepTrailing = (match.namedGroup('dropTrailing') ?? '').isEmpty;
      final leading = match.namedGroup('leading') ?? '';
      final trailing = match.namedGroup('trailing') ?? '';
      return [if (keepLeading) leading, if (keepTrailing) trailing].join();
    });
  });
}
