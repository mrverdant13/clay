import 'dart:io';

import 'package:clay_cli/src/features/config/brick_gen_config_exception.dart';
import 'package:clay_cli/src/features/config/brick_gen_config_file.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// Result of locating `brick-gen.json` and its project root.
class DiscoveredBrickGenConfig {
  /// Creates a [DiscoveredBrickGenConfig].
  const DiscoveredBrickGenConfig({
    required this.configPath,
    required this.projectRoot,
  });

  /// Absolute path to the resolved `brick-gen.json` file.
  final String configPath;

  /// Absolute path to the project root (parent of [configPath]).
  final String projectRoot;
}

/// Collects candidate `brick-gen.json` paths when walking up from [startDir].
@visibleForTesting
List<String> collectConfigSearchPaths({required String startDir}) {
  final normalized = p.normalize(p.absolute(startDir));
  final candidates = <String>[];
  var current = normalized;

  while (true) {
    candidates.add(p.join(current, brickGenConfigFileName));
    final parent = p.dirname(current);
    if (parent == current) {
      break;
    }
    current = parent;
  }

  return candidates;
}

/// Discovers `brick-gen.json` using an explicit [configPath] or walk-up from
/// [cwd].
///
/// When [configPath] is provided, it is resolved relative to [cwd] unless
/// absolute. The parent directory of the config file becomes the project root.
///
/// When [configPath] is omitted, parent directories of [cwd] are searched until
/// a `brick-gen.json` is found or the filesystem root is reached.
DiscoveredBrickGenConfig discoverBrickGenConfig({
  String? configPath,
  String? cwd,
}) {
  final workingDir = p.normalize(p.absolute(cwd ?? Directory.current.path));

  if (configPath != null) {
    final resolvedConfig = p.isAbsolute(configPath)
        ? p.normalize(configPath)
        : p.normalize(p.join(workingDir, configPath));

    if (!File(resolvedConfig).existsSync()) {
      throw BrickGenConfigNotFoundException(
        message: 'brick-gen.json not found at $resolvedConfig',
        searchedPaths: [resolvedConfig],
      );
    }

    return DiscoveredBrickGenConfig(
      configPath: resolvedConfig,
      projectRoot: p.dirname(resolvedConfig),
    );
  }

  final searchedPaths = collectConfigSearchPaths(startDir: workingDir);
  for (final candidate in searchedPaths) {
    if (File(candidate).existsSync()) {
      return DiscoveredBrickGenConfig(
        configPath: candidate,
        projectRoot: p.dirname(candidate),
      );
    }
  }

  throw BrickGenConfigNotFoundException(
    message: 'brick-gen.json not found. Walked up from $workingDir.',
    searchedPaths: searchedPaths,
  );
}
