# Clay

**Clay** is a toolchain for authoring [Mason](https://pub.dev/packages/mason) brick templates from real, runnable **reference projects**. You maintain a reference codebase, mark up files with comment-based **annotations**, and declare transforms in a **`clay.yaml`** config file. The **`clay`** CLI turns that reference into a template directory ready for Mason code generation.

> [!WARNING]
> **Under development.** Clay is pre-release and has not published to pub.dev yet. The CLI, library API, VS Code extension, and `clay.yaml` schema are still evolving — **breaking changes may be introduced** before the first stable release.

| Item              | Value                                                                                         |
| ----------------- | --------------------------------------------------------------------------------------------- |
| Repository        | Standalone monorepo (Melos workspace) |
| Pub package       | [`clay_core`](packages/clay_core/), [`clay_cli`](packages/clay_cli/)                         |
| Executable        | `clay`                                                                                        |
| VS Code extension | **Clay** — [`extensions/clay/`](extensions/clay/)                                             |
| License           | MIT                                                                                           |

---

## Why Clay?

Traditional Mason bricks are authored directly as template files. Clay inverts that workflow:

1. **Write real code** in a reference project (runnable app, package, or snippet tree).
2. **Annotate** files with comment markers (`/*remove-start*/`, `#replace-start#`, etc.) to express what should change at generation time.
3. **Configure** path renames, regex replacements, line deletions, and ignore patterns in `clay.yaml`.
4. **Generate** the Mason `__brick__` output with `clay gen`.

Clay is **brick-agnostic** — no hardcoded project names or monorepo conventions. All project-specific behavior lives in `clay.yaml`, the reference files, and optional CLI overrides.

---

## Quick start

### Typical project layout

Clay does not mandate a directory layout. Reference and target paths are declared in `clay.yaml` and may be overridden via CLI flags. A common convention:

```
my-brick/
├── clay.yaml               # declares "reference" and "target" paths
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

### Install the CLI

After the first pub.dev release:

```bash
dart install clay_cli
```

During local development in this repository, run the CLI via Melos or `dart run` from `packages/clay_cli` (see [Contributing](CONTRIBUTING.md)).

### Generate a template

From the directory that contains `clay.yaml` (or any child directory — Clay walks up parent directories to discover the config):

```bash
clay gen
```

Clay will:

1. Load `clay.yaml` and resolve reference/target paths.
2. Copy the reference tree to the target directory.
3. Apply ignore patterns, path renames, and content transforms (annotations, replacements, line deletions).
4. Print resolved paths and file count to stdout.

### Validate annotations

```bash
clay validate
```

Recursively scans the reference directory and reports `filePath:line:column: message` issues. Exits with code `1` when any issue exists.

### Preview a single file

```bash
# Annotations + clay.yaml transforms only (Mustache tags left intact)
clay preview --file lib/main.dart --template-only

# Full preview with Mason variables
clay preview --file lib/main.dart --vars name=MyApp,useRiverpod=true
```

---

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

Path resolution order: CLI flag → `clay.yaml` field → built-in default (`reference` / `brick/__brick__`). Relative paths resolve from the **project root** (the directory containing `clay.yaml`).

### Commands

| Command    | Description                                                                 |
| ---------- | --------------------------------------------------------------------------- |
| `gen`      | Generate the template from the reference project (default command)          |
| `validate` | Validate annotation markers in the reference directory                      |
| `preview`  | Transform a single reference file and write result to stdout                |
| `compat`   | Check whether the installed Clay version satisfies `environment.clay`       |

#### `clay preview` flags

| Flag               | Description                                                     |
| ------------------ | --------------------------------------------------------------- |
| `--file <path>`    | **Required.** Path to a file under the reference directory      |
| `--template-only`  | Apply config + annotations only; leave Mustache tags unresolved |
| `--vars <k=v,...>` | Comma-separated Mason variables for full preview rendering      |

#### `clay compat`

Read-only probe that loads `clay.yaml` (via the same config discovery and `resolveProjectConfig` path as `gen`, `validate`, and `preview`) and checks whether the installed Clay version satisfies `environment.clay`. It performs no generation, validation, or preview work.

| Exit code | Meaning |
| --- | --- |
| `0` | Compatible — empty stdout and stderr |
| `64` | Usage error (invalid flags) — usage help on stderr |
| `70` | Config or compatibility error — actionable message on stderr |

On version mismatch, stderr matches the message printed by other commands:

```text
The current clay version is 0.0.1-dev.1.
This project requires clay version ^0.2.0.
```

Missing config, invalid `environment.clay`, and other config errors also exit `70` with the same messages as `gen` / `validate` / `preview`. Use `clay compat` in scripts or editor integrations to delegate compatibility checks to the CLI instead of reimplementing semver rules locally.

---

## `clay.yaml`

The config file is the single source of truth for paths, ignore patterns, replacements, line deletions, and optional tool version constraints. Clay discovers `clay.yaml` by walking up from `--cwd` (or the current directory) until a config file is found. Use `--config <path>` to load an explicit file instead.

| Field           | Type       | Default             | Description                                        |
| --------------- | ---------- | ------------------- | -------------------------------------------------- |
| `reference`     | `string`   | `"reference"`       | Path to the reference project root                 |
| `target`        | `string`   | `"brick/__brick__"` | Path to the template output root                   |
| `ignore`        | `string[]` | `[]`                | Gitignore-style glob patterns excluded from output |
| `replacements`  | `array`    | `[]`                | Regex replacements on file paths and contents      |
| `lineDeletions` | `array`    | `[]`                | Line ranges to drop from specific target files     |
| `environment`   | `object`   | *(see below)*       | Semver constraints for tooling required by the project |

Omitted `reference`, `target`, and `ignore` fields use the defaults above.

### `environment.clay`

The optional `environment` block declares which **Clay tool versions** a project supports. It follows the same pattern as Mason's [`environment.mason`](https://github.com/felangel/mason/blob/master/bricks/flavors/brick.yaml) constraint in `brick.yaml`.

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `environment.clay` | `string` | `"any"` | Semver constraint for the installed Clay CLI/library version |

When `environment` is omitted, or `environment.clay` is not set, Clay treats the constraint as **`any`** — existing projects without this field continue to work unchanged.

Pin a constraint when you want `clay gen`, `clay validate`, `clay preview`, and `clay compat` to fail fast if contributors or CI use an incompatible Clay version. For new projects after the first pub.dev preview, a practical starting point is:

```yaml
environment:
  clay: ^0.0.1-dev.1
```

Constraints use [Dart semver](https://pub.dev/packages/pub_semver) syntax (`^`, `>=`, ranges, and so on). When the running Clay version does not satisfy `environment.clay`, commands exit with a non-zero status and an error naming both the current version and the required constraint:

```text
The current clay version is 0.0.1-dev.1.
This project requires clay version ^0.2.0.
```

Authors resolve mismatches by updating `environment.clay` or aligning the installed Clay version — there is no bypass flag.

`replacements` accept a plain string (treated as regex) or `{ pattern: string, dotAll?: boolean }` for the `from` field; `to` supports `${n}` capture-group interpolation. They are applied sequentially to file paths and contents. `lineDeletions` use zero-based, inclusive line ranges relative to the target directory root and run before content replacements and annotation transforms.

`ignore` uses gitignore-compatible syntax (`*`, `**`, leading `/`, `!` negation). During `clay gen`, matching files are excluded from the copied output. Patterns must use POSIX-style forward slashes (`/`) and are interpreted relative to the reference or target root — a leading `/` anchors to that root (for example `/build/` matches only `build/` at the top level), not to the OS filesystem root. Windows-absolute paths such as `C:/...` are rejected when the config is loaded; POSIX-style root anchors such as `/Users/app/build/` are allowed because they match relative to the reference or target root. Backslash separators (`\`) are not supported in ignore patterns.

Further reference docs:

- [`doc/annotations.md`](doc/annotations.md) — marker syntax for reference authors
- [`doc/clay.schema.json`](doc/clay.schema.json) — JSON schema for editor validation and tooling

---

## Annotation overview

Clay supports three comment flavors equivalently:

| Flavor         | Example                                     |
| -------------- | ------------------------------------------- |
| Dart / C-style | `/*remove-start*/` … `/*remove-end*/`       |
| Hash           | `#remove-start#` … `#remove-end#`           |
| HTML           | `<!--remove-start-->` … `<!--remove-end-->` |

Common marker types include `drop`, `remove-start`/`remove-end`, `replace-start`/`with`/`replace-end`, `insert-start`/`insert-end`, Mustache unwrapping in comments, spacing groups (`w <actions> w`), and partials (`partial v <name>` / `partial ^ <name>`). See [`doc/annotations.md`](doc/annotations.md) for full syntax and examples.

Content transforms run in this order: line deletions → content replacements → remotions → replace blocks → insert blocks → Mustache tag unwrapping → spacing groups → partials. Binary files (`.png`, `.webp`) are copied but not text-transformed.

---

## Clay VS Code extension

The **Clay** extension lives in [`extensions/clay/`](extensions/clay/). It provides:

- Annotation syntax highlighting (all marker types, three comment flavors)
- Block/range shading and code folding
- **Clay: Preview generated output** — full Mustache resolution with variable prompts
- **Clay: Preview template output** — annotations + `clay.yaml` transforms only
- Scope discovery via nearest `clay.yaml`
- Configurable annotation colors via `clay.colors.*` settings

The extension invokes the `clay` CLI (installed globally after pub.dev release, or `dart run` during development). Preview commands run `clay compat` before spawning `clay preview` so version checks use the same rules as the CLI — see [`extensions/clay/README.md`](extensions/clay/README.md) for installation, minimum CLI version, settings, preview commands, and troubleshooting.

---

## Repository layout

```
clay/
├── README.md                    # This file
├── CONTRIBUTING.md              # Contributor guide
├── pubspec.yaml                 # Melos workspace root
├── packages/
│   ├── clay_core/               # Core library (config, transforms, generation)
│   │   └── e2e/                 # Library integration tests
│   ├── clay_cli/                # Publishable CLI package
│   │   └── e2e/                 # CLI integration tests
├── extensions/
│   └── clay/                    # VS Code extension
├── doc/                         # User-facing reference docs
└── analysis_options.yaml
```

---

## Programmatic API

Core logic lives in the [`clay_core`](packages/clay_core/) library package, exposed for programmatic use:

```dart
import 'package:clay_core/clay.dart';

Future<ClayConfig> loadClayConfig({required String configPath});

String resolveReferenceContent({
  required String content,
  required String targetRelativePath,
  required ClayConfig config,
});

Future<void> generateTemplate({
  required ClayConfig config,
  required String referencePath,
  required String targetPath,
});

List<AnnotationIssue> validateAnnotations({required Directory referenceDir});
```

Downstream tools should call these APIs rather than duplicating transform logic. Wrappers resolve project-specific paths, then delegate to `clay` with the appropriate config and path values.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for local setup, Melos commands, testing expectations, commit conventions, PR guidelines, and the [Dart package release runbook](CONTRIBUTING.md#dart-package-releases-clay_core-and-clay_cli) for maintainers publishing `clay_core` or `clay_cli` to pub.dev.

---

## Related links

| Resource | URL                                                      |
| -------- | -------------------------------------------------------- |
| Mason    | [pub.dev/packages/mason](https://pub.dev/packages/mason) |
