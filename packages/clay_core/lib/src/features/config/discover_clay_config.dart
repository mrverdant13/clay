import 'dart:io';

import 'package:clay_core/src/features/config/clay_config_exception.dart';
import 'package:clay_core/src/features/config/clay_config_file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Result of locating `clay.yaml` and its project root.
class DiscoveredClayConfig {
  /// Creates a [DiscoveredClayConfig].
  const DiscoveredClayConfig({
    required this.configPath,
    required this.projectRoot,
  });

  /// Absolute path to the resolved `clay.yaml` file.
  final String configPath;

  /// Absolute path to the project root (parent of [configPath]).
  final String projectRoot;
}

/// Collects candidate `clay.yaml` paths when walking up from [startDir].
@visibleForTesting
List<String> collectClayConfigSearchPaths({required String startDir}) {
  final normalized = p.normalize(p.absolute(startDir));
  final candidates = <String>[];
  var current = normalized;

  while (true) {
    candidates.add(p.join(current, clayConfigFileName));
    final parent = p.dirname(current);
    if (parent == current) {
      break;
    }
    current = parent;
  }

  return candidates;
}

/// Discovers `clay.yaml` using an explicit [configPath] or walk-up from [cwd].
///
/// When [configPath] is provided, it is resolved relative to [cwd] unless
/// absolute. The parent directory of the config file becomes the project root.
///
/// When [configPath] is omitted, parent directories of [cwd] are searched until
/// a `clay.yaml` is found or the filesystem root is reached.
DiscoveredClayConfig discoverClayConfig({
  String? configPath,
  String? cwd,
}) {
  final workingDir = p.normalize(p.absolute(cwd ?? Directory.current.path));

  if (configPath != null) {
    final resolvedConfig = p.isAbsolute(configPath)
        ? p.normalize(configPath)
        : p.normalize(p.join(workingDir, configPath));

    if (!File(resolvedConfig).existsSync()) {
      throw ClayConfigNotFoundException(
        message: 'clay.yaml not found at $resolvedConfig',
        searchedPaths: [resolvedConfig],
      );
    }

    return DiscoveredClayConfig(
      configPath: resolvedConfig,
      projectRoot: p.dirname(resolvedConfig),
    );
  }

  final searchedPaths = collectClayConfigSearchPaths(startDir: workingDir);
  for (final candidate in searchedPaths) {
    if (File(candidate).existsSync()) {
      return DiscoveredClayConfig(
        configPath: candidate,
        projectRoot: p.dirname(candidate),
      );
    }
  }

  throw ClayConfigNotFoundException(
    message: 'clay.yaml not found. Walked up from $workingDir.',
    searchedPaths: searchedPaths,
  );
}
