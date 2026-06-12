## 0.0.1

Initial **preview** release of the `clay` core library. This package powers the [`clay_cli`](https://pub.dev/packages/clay_cli) executable and is intended for programmatic use when building Clay integrations.

> **Preview:** APIs and behavior may change before `1.0.0`. Pin to `0.0.1` only for evaluation.

- **FEAT**: public barrel exports for config, generation, preview, transforms, and validation (`clay.dart`).
- **FEAT**: `ClayConfig` entity with `reference`, `target`, `ignore`, `replacements`, and `lineDeletions` fields parsed from `clay.yaml`.
- **FEAT**: config discovery — walk parent directories from a working directory to locate `clay.yaml`.
- **FEAT**: config loading with YAML-to-Dart mapping and descriptive `ClayConfigException` errors.
- **FEAT**: path resolution for reference and target roots relative to the config file directory.
- **FEAT**: gitignore-style `ignore` glob matching for files excluded during generation.
- **FEAT**: `generateTemplate` — copy a reference tree to a target directory, apply ignore patterns, path renames, and content transforms, and prune empty directories.
