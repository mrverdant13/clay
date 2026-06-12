# clay_cli

Command-line interface for **Clay** — generate Mason brick templates from
annotated reference projects using `clay.yaml`.

> **Preview release.** Commands and flags may change before `1.0.0`.

## What it does

The `clay` executable wraps the [`clay`](https://pub.dev/packages/clay) library
with three commands:

- **`clay gen`** — copy a reference project to a target directory and apply
  transforms (ignore patterns, path renames, annotations, replacements)
- **`clay validate`** — scan the reference tree for annotation marker issues
- **`clay preview`** — render a single reference file to stdout with optional
  Mason variable substitution

Clay discovers `clay.yaml` by walking up from the working directory (or
`--cwd`). Use `--config` to load an explicit config file instead.

## Installation

Activate the CLI globally:

```bash
dart pub global activate clay_cli
```

Ensure the pub cache `bin` directory is on your `PATH`, then run `clay`:

```bash
clay --version
```

Requires Dart SDK `>=3.5.0 <4.0.0`.

## Quick start

A typical project layout:

```
my-brick/
├── clay.yaml               # declares reference and target paths
├── reference/              # runnable reference project
│   └── …
└── brick/
    └── __brick__/          # generated template (output of `clay gen`)
        └── …
```

Example `clay.yaml`:

```yaml
reference: reference
target: brick/__brick__
ignore:
  - .dart_tool/
  - build/
  - coverage/
  - "**/*.iml"
  - .DS_Store
replacements: []
lineDeletions: []
```

### Generate a template

From the directory that contains `clay.yaml` (or any child directory):

```bash
clay gen
```

Clay loads the config, copies the reference tree to the target directory,
applies transforms, and prints resolved paths and file count to stdout.
Invoking `clay` without a subcommand runs `gen` by default.

### Validate annotations

```bash
clay validate
```

Recursively scans the reference directory and reports
`filePath:line:column: message` issues. Exits with code `1` when any issue
exists.

### Preview a single file

```bash
# Annotations + clay.yaml transforms only (Mustache tags left intact)
clay preview --file lib/main.dart --template-only

# Full preview with Mason variables
clay preview --file lib/main.dart --vars name=MyApp,useRiverpod=true
```
