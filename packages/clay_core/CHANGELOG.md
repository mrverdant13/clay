## 0.0.1-dev.2

 - **FEAT**: add clay version compatibility check ([#96](https://github.com/mrverdant13/clay/issues/96)). ([064db6ab](https://github.com/mrverdant13/clay/commit/064db6abefeb57ffceb101caca786fd31d9f3efd))
 - **FEAT**: add environment block to ClayConfig ([#95](https://github.com/mrverdant13/clay/issues/95)). ([0591c2ae](https://github.com/mrverdant13/clay/commit/0591c2aea7ee1617c91e9133006c72952f573c4b))
 - **DOCS**: document marker syntax in README and dartdoc ([#131](https://github.com/mrverdant13/clay/issues/131)). ([ad0e8274](https://github.com/mrverdant13/clay/commit/ad0e82745278ecb9f98cb28904ffdd52c40a173a))

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
