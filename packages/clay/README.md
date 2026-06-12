# clay

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

## Installation

Add `clay` to your `pubspec.yaml`:

```yaml
dependencies:
  clay: ^0.0.1
```

Requires Dart SDK `>=3.5.0 <4.0.0`.
