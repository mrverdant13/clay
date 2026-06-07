import 'package:clay_cli/src/entities/brick_gen_config.dart';
import 'package:clay_cli/src/features/transforms/apply_insert_blocks.dart';
import 'package:clay_cli/src/features/transforms/apply_line_deletions.dart';
import 'package:clay_cli/src/features/transforms/apply_mustache_tags.dart';
import 'package:clay_cli/src/features/transforms/apply_partials.dart';
import 'package:clay_cli/src/features/transforms/apply_remotions.dart';
import 'package:clay_cli/src/features/transforms/apply_replace_blocks.dart';
import 'package:clay_cli/src/features/transforms/apply_replacements.dart';
import 'package:clay_cli/src/features/transforms/apply_spacing_groups.dart';
import 'package:clay_cli/src/features/transforms/skip_content_transforms.dart';

/// Applies the annotation and [config] transforms to [content] as if it lived
/// at [targetRelativePath] under [targetAbsolutePath].
///
/// Transforms run in this order: line deletions → content replacements →
/// remotions → replace blocks → insert blocks → Mustache tag unwrapping →
/// spacing groups → partials.
///
/// Binary extensions (`.png`, `.webp`) are returned unchanged.
String resolveReferenceContent({
  required String content,
  required String targetRelativePath,
  required String targetAbsolutePath,
  required BrickGenConfig config,
}) {
  if (shouldSkipContentTransforms(targetRelativePath)) {
    return content;
  }

  return applyPartials(
    content: applySpacingGroups(
      content: applyMustacheTags(
        content: applyInsertBlocks(
          content: applyReplaceBlocks(
            content: applyRemotions(
              content: applyReplacements(
                input: applyLineDeletions(
                  content: content,
                  filePath: targetRelativePath,
                  lineDeletions: config.lineDeletions,
                ),
                replacements: config.replacements,
              ),
            ),
          ),
        ),
      ),
    ),
    targetAbsolutePath: targetAbsolutePath,
  );
}
