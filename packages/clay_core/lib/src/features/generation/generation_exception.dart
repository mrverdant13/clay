/// Thrown when template generation cannot proceed.
class GenerationException implements Exception {
  /// Creates a [GenerationException].
  const GenerationException(this.message);

  /// Human-readable error description.
  final String message;

  @override
  String toString() => message;
}
