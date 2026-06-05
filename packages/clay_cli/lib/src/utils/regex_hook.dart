import 'package:dart_mappable/dart_mappable.dart';
import 'package:meta/meta.dart';

/// A [MappingHook] for encoding and decoding [RegExp] values in JSON.
@visibleForTesting
class RegexHook extends MappingHook {
  /// Creates a [RegexHook].
  @visibleForTesting
  const RegexHook();

  @override
  Object? beforeDecode(Object? value) {
    return switch (value) {
      null => null,
      final RegExp value => value,
      final String value => RegExp(value),
      final Map<String, dynamic> value => () {
          final pattern = value['pattern'] as String;
          final dotAll = value.getOptBool('dotAll');
          final multiLine = value.getOptBool('multiLine');
          final unicode = value.getOptBool('unicode');
          final caseSensitive = value.getOptBool('caseSensitive');
          final dummy = RegExp('.*');
          return RegExp(
            pattern,
            dotAll: dotAll ?? dummy.isDotAll,
            multiLine: multiLine ?? dummy.isMultiLine,
            unicode: unicode ?? dummy.isUnicode,
            caseSensitive: caseSensitive ?? dummy.isCaseSensitive,
          );
        }(),
      _ => RegExp(value.toString()),
    };
  }
}

extension on Map<String, dynamic> {
  bool? getOptBool(String key) {
    return this[key] is bool ? this[key] as bool : null;
  }
}

/// Hook instance for [RegExp] fields in mappable entities.
const regexHook = RegexHook();
