import 'package:clay/clay.dart' show ClayConfig;
import 'package:clay/config.dart';
import 'package:path/path.dart' as p;

/// Resolved Clay project config and its on-disk location.
class ResolvedProjectConfig {
  /// Creates a [ResolvedProjectConfig].
  const ResolvedProjectConfig({
    required this.configPath,
    required this.projectRoot,
    required this.config,
  });

  /// Absolute path to the resolved config file.
  final String configPath;

  /// Absolute path to the project root.
  final String projectRoot;

  /// Parsed project configuration.
  final ClayConfig config;
}

/// Discovers and loads the project config file.
Future<ResolvedProjectConfig> resolveProjectConfig({
  String? configPath,
  String? cwd,
}) async {
  final discovered = discoverProjectConfig(
    configPath: configPath,
    cwd: cwd,
  );
  final config = await loadProjectConfig(configPath: discovered.configPath);

  return ResolvedProjectConfig(
    configPath: discovered.configPath,
    projectRoot: discovered.projectRoot,
    config: config,
  );
}

/// Discovers `clay.yaml`, falling back to `brick-gen.json` when omitted.
///
/// Explicit `--config` paths are resolved as-is. JSON paths remain supported
/// until e2e fixtures migrate in a follow-up PR.
DiscoveredClayConfig discoverProjectConfig({
  String? configPath,
  String? cwd,
}) {
  if (configPath != null) {
    return discoverClayConfig(configPath: configPath, cwd: cwd);
  }

  try {
    return discoverClayConfig(cwd: cwd);
  } on ClayConfigNotFoundException catch (clayError) {
    try {
      final brick = discoverBrickGenConfig(cwd: cwd);
      return DiscoveredClayConfig(
        configPath: brick.configPath,
        projectRoot: brick.projectRoot,
      );
    } on BrickGenConfigNotFoundException {
      throw clayError;
    }
  }
}

/// Loads a config file, routing JSON paths to the legacy loader.
Future<ClayConfig> loadProjectConfig({
  required String configPath,
}) async {
  if (p.extension(configPath).toLowerCase() == '.json') {
    try {
      return await loadBrickGenConfig(configPath: configPath);
    } on BrickGenConfigException catch (error) {
      throw ClayConfigException(error.message);
    }
  }

  return loadClayConfig(configPath: configPath);
}
