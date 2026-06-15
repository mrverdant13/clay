## 0.0.1-dev.1

- **FEAT**: copy binary assets unchanged during template generation (#45).
- **FEAT**: resolve `reference` and `target` paths from `clay.yaml` relative to the config file (#47).
- **FEAT**: exclude reference files from output using gitignore-style `ignore` patterns (#47).
- **FEAT**: transform reference files with comment annotations — remove, replace, and insert blocks; Mustache tags; spacing groups; partials (#48).
- **FEAT**: apply regex `replacements` and `lineDeletions` declared in `clay.yaml` (#48).
- **FEAT**: generate a Mason template tree from a reference project with `generateTemplate` (#49).
- **FEAT**: validate annotation markers across a reference tree with `validateAnnotations` (#49).
- **FEAT**: preview a single reference file with `previewReferenceFile`, with or without Mason variable rendering (#49).
- **FEAT**: load `clay.yaml` from the working directory or parent folders into a typed `ClayConfig` (#54).
