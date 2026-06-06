// ignore_for_file: deprecated_member_use, type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:test_api/test_api.dart';

import 'src/clay_cli_test.dart' as _i1;
import 'src/commands/clay_command_runner_test.dart' as _i2;
import 'src/commands/clay_command_test.dart' as _i3;
import 'src/entities/annotation_issue_test.dart' as _i4;
import 'src/entities/brick_gen_config_test.dart' as _i5;
import 'src/entities/line_deletion_test.dart' as _i6;
import 'src/entities/line_range_test.dart' as _i7;
import 'src/entities/replacement_test.dart' as _i8;
import 'src/utils/regex_hook_test.dart' as _i9;

void main() {
  group(
    'src/clay_cli_test.dart',
    () {
      _i1.main();
    },
  );
  group(
    'src/commands/clay_command_runner_test.dart',
    () {
      _i2.main();
    },
  );
  group(
    'src/commands/clay_command_test.dart',
    () {
      _i3.main();
    },
  );
  group(
    'src/entities/annotation_issue_test.dart',
    () {
      _i4.main();
    },
  );
  group(
    'src/entities/brick_gen_config_test.dart',
    () {
      _i5.main();
    },
  );
  group(
    'src/entities/line_deletion_test.dart',
    () {
      _i6.main();
    },
  );
  group(
    'src/entities/line_range_test.dart',
    () {
      _i7.main();
    },
  );
  group(
    'src/entities/replacement_test.dart',
    () {
      _i8.main();
    },
  );
  group(
    'src/utils/regex_hook_test.dart',
    () {
      _i9.main();
    },
  );
}
