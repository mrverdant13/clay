import 'package:yaml/yaml.dart';

/// Converts a parsed YAML value into plain Dart objects.
Object? yamlToDart(Object? value) {
  if (value is YamlMap) {
    return value.map(
      (key, nested) => MapEntry(key.toString(), yamlToDart(nested)),
    );
  }
  if (value is YamlList) {
    return value.map(yamlToDart).toList();
  }
  return value;
}
