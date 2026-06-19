import 'dart:io';

import 'sync_package_version.dart';

void main(List<String> arguments) {
  final packageName = _readPackageArgument(arguments);
  if (packageName == null) {
    _printUsage();
    exit(64);
  }

  final config = packageConfigs[packageName];
  if (config == null) {
    stderr
      ..writeln('Unknown package: $packageName')
      ..writeln('Supported packages: ${packageConfigs.keys.join(', ')}');
    exit(1);
  }

  final execute = arguments.contains('--execute');
  final verify = arguments.contains('--verify');
  if (execute && verify) {
    stderr.writeln('Cannot pass both --execute and --verify');
    exit(64);
  }

  final repoRoot = _repoRoot();
  final planResult = buildReleaseTagPlan(packageName, config, repoRoot);
  if (planResult.errorMessage != null) {
    stderr.writeln(planResult.errorMessage);
    exit(1);
  }

  final plan = planResult.plan!;

  if (verify) {
    final errorMessage = verifyReleaseTagPlan(plan, repoRoot);
    if (errorMessage != null) {
      stderr.writeln(errorMessage);
      exit(1);
    }
    stdout.writeln('Verified annotated tag ${plan.tagName} on HEAD.');
    exit(0);
  }

  if (!execute) {
    stdout
      ..writeln(
        'Dry run — pass --execute to create and push the annotated tag.',
      )
      ..writeln()
      ..writeln(plan.printCommands());
    exit(0);
  }

  exit(runReleaseTagPlan(plan));
}

/// Describes the annotated git tag to create after a successful publish.
class ReleaseTagPlan {
  const ReleaseTagPlan({
    required this.tagName,
    required this.tagMessage,
  });

  final String tagName;
  final String tagMessage;

  List<List<String>> get gitCommands => [
        ['git', 'tag', '-a', tagName, '-m', tagMessage],
        ['git', 'push', 'origin', tagName],
      ];

  String printCommands() {
    final buffer = StringBuffer();
    for (final command in gitCommands) {
      buffer.writeln(formatShellCommand(command));
    }
    return buffer.toString().trimRight();
  }
}

/// Builds a [ReleaseTagPlan] for [packageName] and [config].
({ReleaseTagPlan? plan, String? errorMessage}) buildReleaseTagPlan(
  String packageName,
  PackageConfig config,
  Directory repoRoot,
) {
  final packageDir = Directory('${repoRoot.path}/${config.packagePath}');
  final pubspecFile = File('${packageDir.path}/pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    return (
      plan: null,
      errorMessage: 'Missing pubspec.yaml: ${pubspecFile.path}',
    );
  }

  final version = readPubspecVersion(pubspecFile);
  final tagName = '$packageName/$version';

  return (
    plan: ReleaseTagPlan(
      tagName: tagName,
      tagMessage: '$packageName $version',
    ),
    errorMessage: null,
  );
}

/// Validates that [plan]'s tag exists, is annotated, and points at HEAD.
///
/// Returns an actionable error message on failure, or `null` when verification
/// succeeds.
String? verifyReleaseTagPlan(ReleaseTagPlan plan, Directory repoRoot) {
  final headResult = _runGit(repoRoot, ['rev-parse', 'HEAD']);
  if (headResult.exitCode != 0) {
    return _gitCommandFailure('git rev-parse HEAD', headResult);
  }

  final headCommit = headResult.stdout.toString().trim();
  final tagRef = 'refs/tags/${plan.tagName}';
  final tagTypeResult = _runGit(repoRoot, ['cat-file', '-t', tagRef]);
  if (tagTypeResult.exitCode != 0) {
    return 'Release tag ${plan.tagName} is missing on this checkout.';
  }

  final tagObjectType = tagTypeResult.stdout.toString().trim();
  final tagCommitResult = _runGit(repoRoot, ['rev-list', '-n', '1', plan.tagName]);
  if (tagCommitResult.exitCode != 0) {
    return _gitCommandFailure('git rev-list -n 1 ${plan.tagName}', tagCommitResult);
  }

  final tagCommit = tagCommitResult.stdout.toString().trim();
  return verifyTagAtHead(
    tagName: plan.tagName,
    headCommit: headCommit,
    tagCommit: tagCommit,
    tagObjectType: tagObjectType,
  );
}

/// Pure validation for release-tag verification logic.
String? verifyTagAtHead({
  required String tagName,
  required String headCommit,
  required String tagCommit,
  required String tagObjectType,
}) {
  if (tagObjectType != 'tag') {
    return 'Release tag $tagName exists but is not annotated.';
  }

  if (tagCommit != headCommit) {
    return 'Release tag $tagName points at $tagCommit but HEAD is $headCommit.';
  }

  return null;
}

/// Runs [plan]'s git commands. Returns the first non-zero exit code, or 0.
int runReleaseTagPlan(ReleaseTagPlan plan) {
  for (final command in plan.gitCommands) {
    final result = Process.runSync(
      command.first,
      command.sublist(1),
    );
    if (result.exitCode != 0) {
      final stderrText = result.stderr.toString().trim();
      if (stderrText.isNotEmpty) {
        stderr.writeln(stderrText);
      }
      return result.exitCode;
    }
  }
  return 0;
}

String formatShellCommand(List<String> command) {
  return command.map(_shellQuote).join(' ');
}

String _shellQuote(String argument) {
  if (RegExp(r'^[A-Za-z0-9_./:@%+=,-]+$').hasMatch(argument)) {
    return argument;
  }

  return "'${argument.replaceAll("'", r"'\''")}'";
}

ProcessResult _runGit(Directory repoRoot, List<String> arguments) {
  return Process.runSync(
    'git',
    arguments,
    workingDirectory: repoRoot.path,
  );
}

String _gitCommandFailure(String command, ProcessResult result) {
  final stderrText = result.stderr.toString().trim();
  if (stderrText.isEmpty) {
    return '$command failed with exit code ${result.exitCode}.';
  }

  return '$command failed: $stderrText';
}

String? _readPackageArgument(List<String> arguments) {
  for (var index = 0; index < arguments.length; index++) {
    final argument = arguments[index];
    if (argument == '--execute' || argument == '--verify') {
      continue;
    }

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

void _printUsage() {
  stderr
    ..writeln(
      'Usage: dart run tool/release_tag.dart --package <name> '
      '[--execute | --verify]',
    )
    ..writeln()
    ..writeln('Creates an annotated tag after a successful pub.dev publish.')
    ..writeln('With --verify, checks that the expected annotated tag is on HEAD.')
    ..writeln('Without --execute or --verify, prints the git commands only.')
    ..writeln()
    ..writeln('Supported packages: ${packageConfigs.keys.join(', ')}');
}
