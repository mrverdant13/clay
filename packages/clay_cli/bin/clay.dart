import 'dart:io';

import 'package:clay_cli/clay_cli.dart';

Future<void> main(List<String> args) async {
  final exitCode = await clay(args: args);
  exit(exitCode);
}
