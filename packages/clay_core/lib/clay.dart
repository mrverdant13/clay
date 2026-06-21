/// Core library for Clay — config, transforms, generation, and validation.
///
/// Clay turns runnable **reference projects** into Mason brick templates using
/// comment-based **annotation markers** in source files and a `clay.yaml`
/// config file.
///
/// Reference authors mark up files with comment tokens such as
/// `/*remove-start*/`, `#replace-start#`, or `<!--partial v header-->`.
/// During generation, markers are resolved and removed from the output tree.
///
/// See the [annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md)
/// for full marker syntax, comment flavors, and examples.
library;

export 'config.dart';
export 'generation.dart';
export 'preview.dart';
export 'src/entities/entities.dart';
export 'src/utils/binary_content.dart';
export 'src/version.dart' show clayCoreVersion;
export 'transforms.dart';
export 'validation.dart';
