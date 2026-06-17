import 'dart:io';

const packageConfigs = <String, PackageConfig>{
  'clay_core': PackageConfig(
    packagePath: 'packages/clay_core',
    versionConstName: 'clayCoreVersion',
  ),
  'clay_cli': PackageConfig(
    packagePath: 'packages/clay_cli',
    versionConstName: 'packageVersion',
  ),
};

final _pubspecVersionPattern = RegExp(
  r'^version:\s+(\S+)\s*$',
  multiLine: true,
);

void main(List<String> arguments) {
  final packageName = _readPackageArgument(arguments);
  if (packageName == null) {
    _printUsage();
    exit(64);
  }

  final config = packageConfigs[packageName];
  if (config == null) {
    stderr.writeln('Unknown package: $packageName');
    stderr.writeln(
      'Supported packages: ${packageConfigs.keys.join(', ')}',
    );
    exit(1);
  }

  exit(syncPackageVersion(config, _repoRoot()));
}

/// Syncs [config]'s `lib/src/version.dart` const from its `pubspec.yaml`.
///
/// Returns `0` on success (including when already in sync) and `1` on failure.
int syncPackageVersion(PackageConfig config, Directory repoRoot) {
  final packageDir = Directory('${repoRoot.path}/${config.packagePath}');
  final pubspecFile = File('${packageDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    stderr.writeln('Missing pubspec.yaml: ${pubspecFile.path}');
    return 1;
  }

  final version = _readPubspecVersion(pubspecFile);
  final versionDartFile = File('${packageDir.path}/lib/src/version.dart');
  if (!versionDartFile.existsSync()) {
    stderr.writeln('Missing version.dart: ${versionDartFile.path}');
    return 1;
  }

  final currentContents = versionDartFile.readAsStringSync();
  final pattern = RegExp(
    "const ${config.versionConstName} = '[^']*';",
  );
  final match = pattern.firstMatch(currentContents);
  if (match == null) {
    stderr.writeln(
      'Could not find const ${config.versionConstName} in '
      '${versionDartFile.path}',
    );
    return 1;
  }

  final updatedConst = "const ${config.versionConstName} = '$version';";
  if (match.group(0) == updatedConst) {
    stdout.writeln(
      '${config.packagePath}: ${config.versionConstName} already matches '
      'pubspec.yaml ($version)',
    );
    return 0;
  }

  final updatedContents = currentContents.replaceFirst(pattern, updatedConst);
  versionDartFile.writeAsStringSync(updatedContents);
  stdout.writeln(
    'Updated ${versionDartFile.path}: '
    '${config.versionConstName} -> $version',
  );
  return 0;
}

String? _readPackageArgument(List<String> arguments) {
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--package') {
      if (index + 1 >= arguments.length) {
        stderr.writeln('Missing value for --package');
        return null;
      }
      return arguments[index + 1];
    }

    const prefix = '--package=';
    if (argument.startsWith(prefix)) {
      final value = argument.substring(prefix.length);
      if (value.isEmpty) {
        stderr.writeln('Missing value for --package');
        return null;
      }
      return value;
    }
  }

  stderr.writeln('Missing required --package argument');
  return null;
}

Directory _repoRoot() {
  final scriptPath = Platform.script.toFilePath();
  final toolDir = File(scriptPath).parent;
  final root = toolDir.parent;
  final pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln(
      'Could not locate monorepo root from script path: $scriptPath',
    );
    exit(1);
  }

  final contents = pubspec.readAsStringSync();
  if (!RegExp(
    r'^name:\s+clay_monorepo\s*$',
    multiLine: true,
  ).hasMatch(contents)) {
    stderr.writeln('Expected clay_monorepo pubspec at ${pubspec.path}');
    exit(1);
  }

  return root;
}

String _readPubspecVersion(File pubspecFile) {
  final match = _pubspecVersionPattern.firstMatch(
    pubspecFile.readAsStringSync(),
  );
  if (match == null) {
    stderr.writeln(
      'Could not read version from pubspec.yaml: ${pubspecFile.path}',
    );
    exit(1);
  }

  final version = match.group(1)!;
  if (version.isEmpty) {
    stderr.writeln(
      'pubspec.yaml version must be a non-empty string: ${pubspecFile.path}',
    );
    exit(1);
  }

  return version;
}

void _printUsage() {
  stderr.writeln(
    'Usage: dart run tool/sync_package_version.dart --package <name>',
  );
  stderr.writeln('');
  stderr.writeln('Supported packages: ${packageConfigs.keys.join(', ')}');
}

class PackageConfig {
  const PackageConfig({
    required this.packagePath,
    required this.versionConstName,
  });

  final String packagePath;
  final String versionConstName;
}
