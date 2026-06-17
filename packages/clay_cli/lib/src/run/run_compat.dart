import 'package:clay_cli/src/run/resolve_project_config.dart';

/// Discovers and loads the project config, asserting clay version
/// compatibility.
Future<ResolvedProjectConfig> runCompat({
  String? configPath,
  String? cwd,
}) {
  return resolveProjectConfig(configPath: configPath, cwd: cwd);
}
