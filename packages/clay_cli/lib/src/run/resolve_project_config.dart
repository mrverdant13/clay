import 'dart:io';

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

/// Discovers `clay.yaml` in the working directory or parent directories.
///
/// Explicit `--config` paths are resolved as-is.
DiscoveredClayConfig discoverProjectConfig({
  String? configPath,
  String? cwd,
}) {
  if (configPath != null) {
    return _discoverExplicitConfig(configPath: configPath, cwd: cwd);
  }

  return discoverClayConfig(cwd: cwd);
}

/// Loads a `clay.yaml` config file.
Future<ClayConfig> loadProjectConfig({
  required String configPath,
}) async {
  return loadClayConfig(configPath: configPath);
}

DiscoveredClayConfig _discoverExplicitConfig({
  required String configPath,
  String? cwd,
}) {
  final workingDir = p.normalize(p.absolute(cwd ?? Directory.current.path));
  final resolvedConfig = p.isAbsolute(configPath)
      ? p.normalize(configPath)
      : p.normalize(p.join(workingDir, configPath));

  if (!File(resolvedConfig).existsSync()) {
    throw ClayConfigNotFoundException(
      message: 'Config file not found at $resolvedConfig',
      searchedPaths: [resolvedConfig],
    );
  }

  return DiscoveredClayConfig(
    configPath: resolvedConfig,
    projectRoot: p.dirname(resolvedConfig),
  );
}
