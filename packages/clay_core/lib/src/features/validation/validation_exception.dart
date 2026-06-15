/// Thrown when annotation validation cannot proceed.
class ValidationException implements Exception {
  /// Creates a [ValidationException].
  const ValidationException(this.message);

  /// Human-readable error description.
  final String message;

  @override
  String toString() => message;
}
