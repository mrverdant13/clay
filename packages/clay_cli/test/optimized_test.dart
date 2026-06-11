// ignore_for_file: deprecated_member_use, type=lint

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:test_api/test_api.dart';

import 'src/clay_cli_test.dart' as _i1;
import 'src/commands/clay_command_runner_test.dart' as _i2;
import 'src/commands/clay_command_test.dart' as _i3;
import 'src/commands/gen_command_test.dart' as _i4;
import 'src/commands/preview_command_test.dart' as _i5;
import 'src/commands/validate_command_test.dart' as _i6;
import 'src/features/config/brick_gen_config_exception_test.dart' as _i7;
import 'src/features/config/discover_brick_gen_config_test.dart' as _i8;
import 'src/features/config/load_brick_gen_config_test.dart' as _i9;
import 'src/features/config/matches_ignore_pattern_test.dart' as _i10;
import 'src/features/config/resolve_paths_test.dart' as _i11;
import 'src/features/generation/assert_distinct_reference_and_target_paths_test.dart'
    as _i12;
import 'src/features/generation/assert_safe_target_path_test.dart' as _i13;
import 'src/features/generation/assert_unique_resolved_paths_test.dart' as _i14;
import 'src/features/generation/copy_directory_test.dart' as _i15;
import 'src/features/generation/generate_template_test.dart' as _i16;
import 'src/features/generation/generation_exception_test.dart' as _i17;
import 'src/features/generation/process_target_file_path_renames_test.dart'
    as _i18;
import 'src/features/generation/process_target_file_test.dart' as _i19;
import 'src/features/generation/process_target_file_transforms_test.dart'
    as _i20;
import 'src/features/generation/prune_empty_directories_test.dart' as _i21;
import 'src/features/generation/resolve_target_file_path_test.dart' as _i22;
import 'src/features/generation/run_gen_test.dart' as _i23;
import 'src/features/preview/parse_preview_vars_test.dart' as _i24;
import 'src/features/preview/preview_exception_test.dart' as _i25;
import 'src/features/preview/run_preview_test.dart' as _i26;
import 'src/features/transforms/apply_insert_blocks_test.dart' as _i27;
import 'src/features/transforms/apply_line_deletions_test.dart' as _i28;
import 'src/features/transforms/apply_mustache_tags_test.dart' as _i29;
import 'src/features/transforms/apply_partials_test.dart' as _i30;
import 'src/features/transforms/apply_remotions_test.dart' as _i31;
import 'src/features/transforms/apply_replace_blocks_test.dart' as _i32;
import 'src/features/transforms/apply_replacements_test.dart' as _i33;
import 'src/features/transforms/apply_spacing_groups_test.dart' as _i34;
import 'src/features/transforms/resolve_reference_content_test.dart' as _i35;
import 'src/features/transforms/skip_content_transforms_test.dart' as _i36;
import 'src/features/validation/annotation_validator_test.dart' as _i37;
import 'src/features/validation/run_validate_test.dart' as _i38;
import 'src/features/validation/validation_exception_test.dart' as _i39;
import 'src/public_api/import_boundary_test.dart' as _i40;

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
    'src/commands/gen_command_test.dart',
    () {
      _i4.main();
    },
  );
  group(
    'src/commands/preview_command_test.dart',
    () {
      _i5.main();
    },
  );
  group(
    'src/commands/validate_command_test.dart',
    () {
      _i6.main();
    },
  );
  group(
    'src/features/config/brick_gen_config_exception_test.dart',
    () {
      _i7.main();
    },
  );
  group(
    'src/features/config/discover_brick_gen_config_test.dart',
    () {
      _i8.main();
    },
  );
  group(
    'src/features/config/load_brick_gen_config_test.dart',
    () {
      _i9.main();
    },
  );
  group(
    'src/features/config/matches_ignore_pattern_test.dart',
    () {
      _i10.main();
    },
  );
  group(
    'src/features/config/resolve_paths_test.dart',
    () {
      _i11.main();
    },
  );
  group(
    'src/features/generation/assert_distinct_reference_and_target_paths_test.dart',
    () {
      _i12.main();
    },
  );
  group(
    'src/features/generation/assert_safe_target_path_test.dart',
    () {
      _i13.main();
    },
  );
  group(
    'src/features/generation/assert_unique_resolved_paths_test.dart',
    () {
      _i14.main();
    },
  );
  group(
    'src/features/generation/copy_directory_test.dart',
    () {
      _i15.main();
    },
  );
  group(
    'src/features/generation/generate_template_test.dart',
    () {
      _i16.main();
    },
  );
  group(
    'src/features/generation/generation_exception_test.dart',
    () {
      _i17.main();
    },
  );
  group(
    'src/features/generation/process_target_file_path_renames_test.dart',
    () {
      _i18.main();
    },
  );
  group(
    'src/features/generation/process_target_file_test.dart',
    () {
      _i19.main();
    },
  );
  group(
    'src/features/generation/process_target_file_transforms_test.dart',
    () {
      _i20.main();
    },
  );
  group(
    'src/features/generation/prune_empty_directories_test.dart',
    () {
      _i21.main();
    },
  );
  group(
    'src/features/generation/resolve_target_file_path_test.dart',
    () {
      _i22.main();
    },
  );
  group(
    'src/features/generation/run_gen_test.dart',
    () {
      _i23.main();
    },
  );
  group(
    'src/features/preview/parse_preview_vars_test.dart',
    () {
      _i24.main();
    },
  );
  group(
    'src/features/preview/preview_exception_test.dart',
    () {
      _i25.main();
    },
  );
  group(
    'src/features/preview/run_preview_test.dart',
    () {
      _i26.main();
    },
  );
  group(
    'src/features/transforms/apply_insert_blocks_test.dart',
    () {
      _i27.main();
    },
  );
  group(
    'src/features/transforms/apply_line_deletions_test.dart',
    () {
      _i28.main();
    },
  );
  group(
    'src/features/transforms/apply_mustache_tags_test.dart',
    () {
      _i29.main();
    },
  );
  group(
    'src/features/transforms/apply_partials_test.dart',
    () {
      _i30.main();
    },
  );
  group(
    'src/features/transforms/apply_remotions_test.dart',
    () {
      _i31.main();
    },
  );
  group(
    'src/features/transforms/apply_replace_blocks_test.dart',
    () {
      _i32.main();
    },
  );
  group(
    'src/features/transforms/apply_replacements_test.dart',
    () {
      _i33.main();
    },
  );
  group(
    'src/features/transforms/apply_spacing_groups_test.dart',
    () {
      _i34.main();
    },
  );
  group(
    'src/features/transforms/resolve_reference_content_test.dart',
    () {
      _i35.main();
    },
  );
  group(
    'src/features/transforms/skip_content_transforms_test.dart',
    () {
      _i36.main();
    },
  );
  group(
    'src/features/validation/annotation_validator_test.dart',
    () {
      _i37.main();
    },
  );
  group(
    'src/features/validation/run_validate_test.dart',
    () {
      _i38.main();
    },
  );
  group(
    'src/features/validation/validation_exception_test.dart',
    () {
      _i39.main();
    },
  );
  group(
    'src/public_api/import_boundary_test.dart',
    () {
      _i40.main();
    },
  );
}
