# Clay

**Clay** is a toolchain for authoring [Mason](https://pub.dev/packages/mason) brick templates from real, runnable **reference projects**. You maintain a reference codebase, mark up files with comment-based **annotations**, and declare transforms in a **`brick-gen.json`** config file. The **`clay`** CLI turns that reference into a template directory ready for Mason code generation.

| Item              | Value                                                                                         |
| ----------------- | --------------------------------------------------------------------------------------------- |
| Repository        | Standalone monorepo (Melos workspace) |
| Pub package       | [`clay_cli`](packages/clay_cli/)                                                              |
| Executable        | `clay`                                                                                        |
| VS Code extension | **Clay** — [`extensions/clay/`](extensions/clay/)                                             |
| License           | MIT                                                                                           |

> **Status:** Early-stage repository. The CLI, library, and VS Code extension packages are being scaffolded.

---

## Why Clay?

Traditional Mason bricks are authored directly as template files. Clay inverts that workflow:

1. **Write real code** in a reference project (runnable app, package, or snippet tree).
2. **Annotate** files with comment markers (`/*remove-start*/`, `#replace-start#`, etc.) to express what should change at generation time.
3. **Configure** path renames, regex replacements, line deletions, and ignore patterns in `brick-gen.json`.
4. **Generate** the Mason `__brick__` output with `clay gen`.

Clay is **brick-agnostic** — no hardcoded project names or monorepo conventions. All project-specific behavior lives in `brick-gen.json`, the reference files, and optional CLI overrides.

---

## Quick start

### Typical project layout

Clay does not mandate a directory layout. Reference and target paths are declared in `brick-gen.json` and may be overridden via CLI flags. A common convention:

```
my-brick/
├── brick-gen.json          # declares "reference" and "target" paths
├── reference/              # runnable reference project
│   └── …
└── brick/
    └── __brick__/          # generated template (output of `clay gen`)
        └── …
```

Example `brick-gen.json`:

```json
{
  "reference": "reference",
  "target": "brick/__brick__",
  "ignore": [
    ".dart_tool/",
    "build/",
    "coverage/",
    "**/*.iml",
    ".DS_Store"
  ],
  "replacements": [],
  "lineDeletions": []
}
```

### Install the CLI

After the first pub.dev release:

```bash
dart pub global activate clay_cli
```

During local development in this repository, run the CLI via Melos or `dart run` from `packages/clay_cli` (see [Contributing](CONTRIBUTING.md)).

### Generate a template

From the directory that contains `brick-gen.json` (or any child directory — Clay walks up to discover the config):

```bash
clay gen
```

Clay will:

1. Load `brick-gen.json` and resolve reference/target paths.
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
# Annotations + brick-gen.json transforms only (Mustache tags left intact)
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
| `--config <path>` | Path to `brick-gen.json` (skips discovery)                          |
| `--cwd <path>`    | Working directory for config discovery (default: current directory) |

### Shared command flags

| Flag                 | Default         | Description                              |
| -------------------- | --------------- | ---------------------------------------- |
| `--reference <path>` | *(from config)* | Overrides `brick-gen.json` → `reference` |
| `--target <path>`    | *(from config)* | Overrides `brick-gen.json` → `target`    |

Path resolution order: CLI flag → `brick-gen.json` field → built-in default (`reference` / `brick/__brick__`). Relative paths resolve from the **project root** (the directory containing `brick-gen.json`).

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

---

## `brick-gen.json`

The config file is the single source of truth for paths, ignore patterns, replacements, and line deletions.

| Field           | Type       | Default             | Description                                        |
| --------------- | ---------- | ------------------- | -------------------------------------------------- |
| `reference`     | `string`   | `"reference"`       | Path to the reference project root                 |
| `target`        | `string`   | `"brick/__brick__"` | Path to the template output root                   |
| `ignore`        | `string[]` | `[]`                | Gitignore-style glob patterns excluded from output |
| `replacements`  | `array`    | `[]`                | Regex replacements on file paths and contents      |
| `lineDeletions` | `array`    | `[]`                | Line ranges to drop from specific target files     |

Clay accepts legacy config files that omit `reference`, `target`, and `ignore`; missing path fields fall back to the defaults above.

`replacements` accept a plain string (treated as regex) or `{ "pattern": string, "dotAll"?: boolean }` for the `from` field; `to` supports `${n}` capture-group interpolation. They are applied sequentially to file paths and contents. `lineDeletions` use zero-based, inclusive line ranges relative to the target directory root and run before content replacements and annotation transforms.

`ignore` uses gitignore-compatible syntax (`*`, `**`, leading `/`, `!` negation). During `clay gen`, matching files are excluded from the copied output.

Further reference docs (planned):

- [`doc/annotations.md`](doc/annotations.md) — marker syntax for reference authors
- [`doc/brick-gen.schema.json`](doc/brick-gen.schema.json) — JSON schema

---

## Annotation overview

Clay supports three comment flavors equivalently:

| Flavor         | Example                                     |
| -------------- | ------------------------------------------- |
| Dart / C-style | `/*remove-start*/` … `/*remove-end*/`       |
| Hash           | `#remove-start#` … `#remove-end#`           |
| HTML           | `<!--remove-start-->` … `<!--remove-end-->` |

Common marker types include `drop`, `remove-start`/`remove-end`, `replace-start`/`with`/`replace-end`, `insert-start`/`insert-end`, Mustache unwrapping in comments, spacing groups (`w <actions> w`), and partials (`partial v <name>` / `partial ^ <name>`).

Content transforms run in this order: line deletions → content replacements → remotions → replace blocks → insert blocks → Mustache tag unwrapping → spacing groups → partials. Binary files (`.png`, `.webp`) are copied but not text-transformed.

---

## Clay VS Code extension

The **Clay** extension lives in [`extensions/clay/`](extensions/clay/). It provides:

- Annotation syntax highlighting (all marker types, three comment flavors)
- Block/range shading and code folding
- **Clay: Preview generated output** — full Mustache resolution with variable prompts
- **Clay: Preview template output** — annotations + `brick-gen.json` transforms only
- Scope discovery via nearest `brick-gen.json`
- Configurable annotation colors via `clay.colors.*` settings

The extension invokes the `clay` CLI (installed globally after pub.dev release, or `dart run` during development). Extension-specific setup will be documented in `extensions/clay/README.md` once scaffolded.

---

## Repository layout

```
clay/
├── README.md                    # This file
├── CONTRIBUTING.md              # Contributor guide
├── pubspec.yaml                 # Melos workspace root
├── packages/
│   ├── clay_cli/                # Publishable Dart package
│   └── clay_cli_e2e/            # CLI integration tests
├── extensions/
│   └── clay/                    # VS Code extension
├── doc/                         # User-facing reference docs (planned)
└── analysis_options.yaml
```

---

## Programmatic API

Core logic is exposed as a Dart library, not only as a CLI executable:

```dart
Future<BrickGenConfig> loadBrickGenConfig({required String configPath});

String resolveReferenceContent({
  required String content,
  required String targetRelativePath,
  required BrickGenConfig config,
});

Future<void> generateTemplate({
  required BrickGenConfig config,
  required String referencePath,
  required String targetPath,
});

List<AnnotationIssue> validateAnnotations({required Directory referenceDir});
```

Downstream tools (e.g. monorepo wrappers) should call these APIs rather than duplicating transform logic. Wrappers resolve project-specific paths, then delegate to `clay_cli` with the appropriate `--config`, `reference`, and `target` values.

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for local setup, Melos commands, testing expectations, commit conventions, PR guidelines, and implementation milestones.

---

## Related links

| Resource | URL                                                      |
| -------- | -------------------------------------------------------- |
| Mason    | [pub.dev/packages/mason](https://pub.dev/packages/mason) |
