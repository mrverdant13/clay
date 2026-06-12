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
