import 'dart:io';

import 'package:clay/clay.dart';

Future<void> main() async {
  final exampleRoot = File(Platform.script.toFilePath()).parent.path;

  final discovered = discoverClayConfig(cwd: exampleRoot);
  final config = await loadClayConfig(configPath: discovered.configPath);

  final referencePath = resolveReferencePath(
    projectRoot: discovered.projectRoot,
    config: config,
  );
  final targetPath = resolveTargetPath(
    projectRoot: discovered.projectRoot,
    config: config,
  );

  stdout.writeln('Generating template...');
  stdout.writeln('  reference: $referencePath');
  stdout.writeln('  target:    $targetPath');

  await generateTemplate(
    config: config,
    referencePath: referencePath,
    targetPath: targetPath,
  );

  final issues = validateAnnotations(
    referenceDir: Directory(referencePath),
  );
  if (issues.isEmpty) {
    stdout.writeln('Validation: no annotation issues.');
  } else {
    stdout.writeln('Validation issues:');
    for (final issue in issues) {
      stdout.writeln('  $issue');
    }
  }

  const previewFile = 'lib/ref_pkg/greeting.dart.ref';
  final preview = await previewReferenceFile(
    filePath: previewFile,
    referencePath: referencePath,
    config: config,
    templateOnly: true,
  );

  stdout.writeln('Preview ($previewFile, template-only):');
  stdout.writeln(preview);
}
