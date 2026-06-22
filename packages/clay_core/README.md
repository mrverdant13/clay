# clay_core

Core Dart library for **Clay** — load `clay.yaml`, transform annotated reference
projects, and generate Mason brick templates.

> **Preview release.** APIs may change before `1.0.0`.

## What it does

Clay turns a runnable **reference project** into a Mason **`__brick__`** template
tree. This library provides:

- **`clay.yaml` parsing** — typed `ClayConfig` with reference and target paths,
  ignore patterns, regex replacements, and line deletions
- **Annotation transforms** — remove, replace, and insert blocks; Mustache tags;
  spacing groups; partials
- **Template generation** — copy a reference tree to a target directory and
  apply transforms
- **Validation** — scan reference files for annotation marker issues
- **Preview** — render a single reference file with optional Mason variable
  substitution

For day-to-day use, install the [`clay_cli`](https://pub.dev/packages/clay_cli)
package (`clay gen`, `clay validate`, `clay preview`). Use this library when
embedding Clay in tools or automation.

## Annotation markers

Reference files use **comment-based markers** to express what should change at
generation time. Clay supports three equivalent comment flavors — pick the one
that matches the file type:

| Flavor  | Delimiters   | Example                                     |
| ------- | ------------ | ------------------------------------------- |
| C-style | `/* … */`    | `/*remove-start*/` … `/*remove-end*/`       |
| Hash    | `# … #`      | `#remove-start#` … `#remove-end#`           |
| HTML    | `<!-- … -->` | `<!--remove-start-->` … `<!--remove-end-->` |

Common markers (C-style shown; keywords are the same in every flavor):

| Marker                                   | Purpose                                  |
| ---------------------------------------- | ---------------------------------------- |
| `drop`                                   | Remove from marker to end of file        |
| `remove-start` / `remove-end`            | Remove a content block                   |
| `replace-start` / `with` / `replace-end` | Replace scaffold with template lines     |
| `insert-start` / `insert-end`            | Insert template lines at a position      |
| `/*{{name}}*/`                           | Unwrap a Mustache tag for Mason          |
| `w <actions> w`                          | Expand newlines (`Nv`) and spaces (`N>`) |
| `partial v <name>` / `partial ^ <name>`  | Extract a Mason partial                  |

**Example** — remove, replace, and Mustache markers in a `pubspec.yaml` reference file.

`clay.yaml`:

```yaml
reference: reference
target: brick/__brick__
replacements:
  - from: my_package
    to: "{{package_name.snakeCase()}}"
  - from: A Dart package scaffold.
    to: "{{package_description}}"
```

Reference (`reference/my_package/pubspec.yaml`):

```yaml
name: my_package
description: A Dart package scaffold.
publish_to: none
#x-remove-start#
resolution: workspace
#remove-end#

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  shared_utils:
    #replace-start#
    path: ../../../workspace/shared_utils/
    #with#
    # path: ../shared_utils/
    #replace-end#

dev_dependencies:
  #{{#use_code_generation}}x#
  build_runner: ^2.10.5
  #{{/use_code_generation}}x#
  #remove-start#
  coverde: ^0.3.0
  #remove-end-x#
  test: ^1.31.1
```

Template output (`brick/__brick__/my_package/pubspec.yaml`, after `clay gen`):

```yaml
name: {{package_name.snakeCase()}}
description: {{package_description}}
publish_to: none

environment:
  sdk: ">=3.5.0 <4.0.0"

dependencies:
  shared_utils:
    path: ../shared_utils/

dev_dependencies:
  {{#use_code_generation}}build_runner: ^2.10.5
  {{/use_code_generation}}test: ^1.31.1
```

Use [`validateAnnotations`](https://pub.dev/documentation/clay_core/latest/validation/validateAnnotations.html)
to scan for unmatched markers, or [`resolveReferenceContent`](https://pub.dev/documentation/clay_core/latest/transforms/resolveReferenceContent.html)
to apply the full transform pipeline programmatically.

Full syntax, whitespace flags, validation rules, and per-marker examples:
[Annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md).

## Installation

Add `clay_core` to your `pubspec.yaml`:

```yaml
dependencies:
  clay_core: ^0.0.1-dev.2
```

Requires Dart SDK `>=3.5.0 <4.0.0`.

## Usage

Discover `clay.yaml`, resolve paths, generate a template, and validate
annotations:

```dart
import 'dart:io';

import 'package:clay_core/clay.dart';

Future<void> main() async {
  final discovered = discoverClayConfig();
  final config = await loadClayConfig(configPath: discovered.configPath);

  final referencePath = resolveReferencePath(
    projectRoot: discovered.projectRoot,
    config: config,
  );
  final targetPath = resolveTargetPath(
    projectRoot: discovered.projectRoot,
    config: config,
  );

  await generateTemplate(
    config: config,
    referencePath: referencePath,
    targetPath: targetPath,
  );

  final issues = validateAnnotations(
    referenceDir: Directory(referencePath),
  );
  for (final issue in issues) {
    stdout.writeln(issue);
  }
}
```

Preview a single file without Mason rendering (`templateOnly: true`):

```dart
final output = await previewReferenceFile(
  filePath: 'lib/main.dart',
  referencePath: referencePath,
  config: config,
  templateOnly: true,
);
```

## Public API

Import `package:clay_core/clay.dart`, or narrower libraries such as `config.dart`,
`generation.dart`, `preview.dart`, `transforms.dart`, and `validation.dart`.

| Area       | Key symbols                                                                                       |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Config     | `discoverClayConfig`, `loadClayConfig`, `ClayConfig`, `resolveReferencePath`, `resolveTargetPath` |
| Generation | `generateTemplate`                                                                                |
| Validation | `validateAnnotations`, `AnnotationIssue`                                                          |
| Preview    | `previewReferenceFile`, `parsePreviewVars`                                                        |

## Resources

- [Annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md) — marker syntax for reference authors
- [Repository](https://github.com/mrverdant13/clay/tree/main/packages/clay_core)
- [Issue tracker](https://github.com/mrverdant13/clay/issues)
- [Changelog](CHANGELOG.md)

## License

MIT — see [LICENSE](LICENSE).
