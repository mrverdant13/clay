## 0.0.1

- **FEAT**: binary file detection — image and other binary assets are copied without text transforms (#45).
- **FEAT**: path resolution for reference and target roots relative to the config file directory (#47).
- **FEAT**: gitignore-style `ignore` glob matching for files excluded during generation (#47).
- **FEAT**: annotation transform pipeline — remotions, replace/insert blocks, Mustache unwrapping, spacing groups, and partials across C-style, hash, and HTML comment flavors (#48).
- **FEAT**: `clay.yaml` regex `replacements` and per-file `lineDeletions` applied before annotation transforms (#48).
- **FEAT**: `generateTemplate` — copy a reference tree to a target directory, apply ignore patterns, path renames, and content transforms, and prune empty directories (#49).
- **FEAT**: `validateAnnotations` — recursive reference scan with `filePath:line:column: message` issue formatting (#49).
- **FEAT**: `previewReferenceFile` — single-file preview with optional Mason variable rendering (`templateOnly` mode preserves Mustache tags) (#49).
- **FEAT**: export exception types from generation and validation entry points (#50).
- **FEAT**: public barrel exports for config, generation, preview, transforms, and validation (`clay.dart`) (#52).
- **TEST**: unit tests for config, generation, transforms, preview, and validation; import-boundary enforcement for the public API (#53).
- **FEAT**: `ClayConfig` entity with `reference`, `target`, `ignore`, `replacements`, and `lineDeletions` fields parsed from `clay.yaml` (#54).
- **FEAT**: config discovery — walk parent directories from a working directory to locate `clay.yaml` (#54).
- **FEAT**: config loading with YAML-to-Dart mapping and descriptive `ClayConfigException` errors (#54).
