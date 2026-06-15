/// Thrown when preview cannot proceed.
class PreviewException implements Exception {
  /// Creates a [PreviewException].
  const PreviewException(this.message);

  /// Human-readable error description.
  final String message;

  @override
  String toString() => message;
}
