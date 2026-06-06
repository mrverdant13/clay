import 'dart:io';

import 'package:clay_cli/clay_cli.dart';
import 'package:mason/mason.dart';

Future<void> main(List<String> args) async {
  final logger = Logger();
  final exitCode = await clay(
    args: args,
    logger: logger,
  );
  exit(exitCode);
}
