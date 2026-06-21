# clay_cli

Command-line interface for **Clay** — generate Mason brick templates from
annotated reference projects using `clay.yaml`.

> **Preview release.** Commands and flags may change before `1.0.0`.

## What it does

The `clay` executable wraps the [`clay_core`](https://pub.dev/packages/clay_core) library
with three commands:

- **`clay gen`** — copy a reference project to a target directory and apply
  transforms (ignore patterns, path renames, annotations, replacements)
- **`clay validate`** — scan the reference tree for annotation marker issues
- **`clay preview`** — render a single reference file to stdout with optional
  Mason variable substitution

Clay discovers `clay.yaml` by walking up from the working directory (or
`--cwd`). Use `--config` to load an explicit config file instead.

## Annotation markers

Annotate reference files with **comment-based markers** to control what appears
in the generated Mason template. Three comment flavors are equivalent — use the
one that matches each file:

| Flavor | Delimiters | Typical files |
| --- | --- | --- |
| C-style | `/* … */` | `.dart`, `.js`, `.ts` |
| Hash | `# … #` | `.sh`, `.yaml`, `.gitignore` |
| HTML | `<!-- … -->` | `.html`, `.md`, `.xml` |

| Marker | Purpose |
| --- | --- |
| `drop` | Remove from marker to end of file |
| `remove-start` / `remove-end` | Remove a content block |
| `replace-start` / `with` / `replace-end` | Replace scaffold with template lines |
| `insert-start` / `insert-end` | Insert template lines at a position |
| `{{…}}` in a comment | Unwrap Mustache tags for Mason |
| `w <actions> w` | Expand newlines (`Nv`) and spaces (`N>`) |
| `partial v <name>` / `partial ^ <name>` | Extract a Mason partial |

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

Try it on one file before generating the full tree:

```bash
clay validate
clay preview --file my_package/pubspec.yaml --template-only
clay gen
```

**Workflow:**

1. Add markers to files under the configured `reference` directory.
2. Run `clay validate` to check marker pairing and block structure.
3. Run `clay preview --file <path> --template-only` to inspect one file.
4. Run `clay gen` to write the full template tree.

Full syntax, whitespace flags, and examples:
[Annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md).

## Installation

Install the CLI globally with [`dart install`](https://dart.dev/tools/dart-install):

```bash
dart install clay_cli
```

Verify the `clay` executable is available:

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

## CLI reference

### Invocation

```
clay [--config <path>] [--cwd <path>] [--verbose] [--version] <command> [options]
```

### Global flags

| Flag              | Description                                                         |
| ----------------- | ------------------------------------------------------------------- |
| `--version`       | Print package version                                               |
| `--verbose`       | Verbose logging (resolved paths, excluded files)                    |
| `--config <path>` | Path to `clay.yaml` (skips discovery; any filename is accepted)     |
| `--cwd <path>`    | Working directory for config discovery (default: current directory) |

### Shared command flags

| Flag                 | Default         | Description                           |
| -------------------- | --------------- | ------------------------------------- |
| `--reference <path>` | *(from config)* | Overrides `clay.yaml` → `reference`   |
| `--target <path>`    | *(from config)* | Overrides `clay.yaml` → `target`      |

Path resolution order: CLI flag → `clay.yaml` field → built-in default
(`reference` / `brick/__brick__`). Relative paths resolve from the **project
root** (the directory containing `clay.yaml`).

### Commands

| Command    | Description                                                        |
| ---------- | ------------------------------------------------------------------ |
| `gen`      | Generate the template from the reference project (default command) |
| `validate` | Validate annotation markers in the reference directory             |
| `preview`  | Transform a single reference file and write result to stdout       |

#### `clay preview` flags

| Flag               | Description                                                     |
| ------------------ | --------------------------------------------------------------- |
| `--file <path>`    | **Required.** Path to a file under the reference directory      |
| `--template-only`  | Apply config + annotations only; leave Mustache tags unresolved |
| `--vars <k=v,...>` | Comma-separated Mason variables for full preview rendering      |

## Resources

- [Annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md) — marker syntax for reference authors
- [Repository](https://github.com/mrverdant13/clay/tree/main/packages/clay_cli)
- [Issue tracker](https://github.com/mrverdant13/clay/issues)
- [Changelog](CHANGELOG.md)
- [`clay_core` library](https://pub.dev/packages/clay_core) — embed Clay in Dart tools

## License

MIT — see [LICENSE](LICENSE).
