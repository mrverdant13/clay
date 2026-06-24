# Changelog

All notable changes to the Clay VS Code extension are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.1-dev.1] - 2026-06-23

Preview release. Editor support for Clay annotation markers in reference projects, with preview commands gated by `clay compat`.

### Added

- TextMate grammar injection for Clay annotation markers in Dart, Shell, YAML, HTML, XML, Markdown, and ignore files.
- Block shading and configurable `clay.colors.*` settings for remove, replace, insert, partial, Mustache, and spacing markers.
- Code folding for remove, replace, and partial annotation blocks.
- **Clay: Preview template output** — runs `clay preview --template-only` for the active reference file.
- **Clay: Preview generated output** — prompts for brick and file-level variables, then runs `clay preview --vars` and shows a diff against the saved reference file.
- `clay compat` gating before each preview; non-zero stderr from compatibility checks blocks preview.
- CLI resolution via `clay.cliPath`, `PATH`, Dart install bin, pub-cache bin, or the workspace `packages/clay_cli` script.
- Brick scope discovery from the nearest `clay.yaml` and configured `reference` path.
- Session-scoped variable value persistence for generated preview per brick scope.

### Requirements

- VS Code 1.85 or newer.
- [`clay_cli`](https://pub.dev/packages/clay_cli) **`0.0.1-dev.2`** or newer (includes the `clay compat` subcommand).

[Unreleased]: https://github.com/mrverdant13/clay/compare/clay_vsc_extension/0.0.1-dev.1...HEAD
[0.0.1-dev.1]: https://github.com/mrverdant13/clay/releases/tag/clay_vsc_extension%2F0.0.1-dev.1
