/// Thrown when `brick-gen.json` cannot be loaded or parsed.
class BrickGenConfigException implements Exception {
  /// Creates a [BrickGenConfigException].
  const BrickGenConfigException(this.message);

  /// Human-readable error description.
  final String message;

  @override
  String toString() => message;
}

/// Thrown when `brick-gen.json` cannot be discovered.
class BrickGenConfigNotFoundException implements Exception {
  /// Creates a [BrickGenConfigNotFoundException].
  const BrickGenConfigNotFoundException({
    required this.message,
    required this.searchedPaths,
  });

  /// Human-readable error description.
  final String message;

  /// Candidate paths checked during discovery.
  final List<String> searchedPaths;

  @override
  String toString() {
    final buffer = StringBuffer(message);
    if (searchedPaths.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('Searched paths:')
        ..writeAll(searchedPaths.map((path) => '  $path'), '\n');
    }
    return buffer.toString();
  }
}
