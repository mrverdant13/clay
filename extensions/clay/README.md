# Clay — VS Code extension

Editor support for [Clay](https://github.com/mrverdant13/clay) annotation markers in reference projects. The extension complements the [`clay`](../../packages/clay_cli/) CLI by providing in-editor tooling for authoring Mason brick templates from runnable reference code.

---

## Prerequisites

- **VS Code** 1.85 or newer
- **`clay` CLI** — required for preview commands (see [CLI setup](#cli-setup) below)

For extension development only:

- **Node.js** 20.x
- **pnpm** 9.x — [installation guide](https://pnpm.io/installation), or:
  ```bash
  corepack enable
  corepack prepare pnpm@9 --activate
  ```

---

## Installation

### From the Marketplace

The Clay extension will be published to the [Visual Studio Marketplace](https://marketplace.visualstudio.com/) alongside the first `clay_cli` release. Until then, install from a VSIX (see below) or run the extension from source during development.

### From a VSIX

Build a package from this repository:

```bash
cd extensions/clay
pnpm install
pnpm run package
```

Install the generated `.vsix` in VS Code:

1. Open the Command Palette (`Cmd+Shift+P` / `Ctrl+Shift+P`).
2. Run **Extensions: Install from VSIX…**.
3. Select the `.vsix` file produced by `pnpm run package`.

### Development (Extension Development Host)

From the repository root:

```bash
cd extensions/clay
pnpm install
pnpm run compile
```

Open the **clay** monorepo in VS Code, then start the **Run Clay Extension** launch configuration from the Run and Debug panel. This opens a new window with the extension loaded against your workspace.

---

## CLI setup

Preview commands spawn the `clay` CLI. The extension resolves an executable in this order:

1. **`clay.cliPath`** — when set in workspace or user settings, this path is tried first.
2. **`clay`** on `PATH`.
3. **Dart install bin** — platform-specific default location under the Dart SDK install.
4. **Pub-cache bin** — `~/.pub-cache/bin/clay` (or `%LOCALAPPDATA%\Pub\Cache\bin\clay.bat` on Windows).
5. **Workspace package** — when a workspace folder contains `packages/clay_cli/bin/clay.dart`, the extension runs `dart run` against that script automatically.

During monorepo development, open the clay repository (or any workspace that includes `packages/clay_cli`) and preview commands work without extra configuration.

After `clay_cli` is published to pub.dev:

```bash
dart pub global activate clay_cli
```

Ensure the pub-cache `bin` directory is on your `PATH`, or set `clay.cliPath` to the absolute path of the `clay` executable.

Verify the CLI is available:

```bash
clay preview --help
# or, during development:
dart run packages/clay_cli/bin/clay.dart preview --help
```

---

## Using the extension

### Open a reference project

Open a folder that contains a `brick-gen.json` config and a reference tree (see the [root README](../../README.md) for a typical layout). The extension discovers scope by walking up from the active file to the nearest `brick-gen.json`, then verifying the file lies under the configured `reference` path.

Preview commands and scope-dependent features require a valid brick scope. If a file is outside every configured reference root, the extension shows a warning and does not run the CLI.

### Supported file types

Annotation highlighting, folding, shading, and preview commands apply to:

| Kind | Extensions / names |
| --- | --- |
| Dart | `.dart` |
| Shell | `.sh` |
| YAML | `.yaml`, `.yml` |
| HTML / XML | `.html`, `.htm`, `.xml` |
| Markdown | `.md`, `.markdown` |
| Ignore files | `.gitignore`, `.dockerignore` |

Three comment flavors are supported equivalently: C-style (`/* … */`), hash (`# … #`), and HTML (`<!-- … -->`). See [`doc/annotations.md`](../../doc/annotations.md) for marker syntax.

### Preview commands

Both commands are available from the editor context menu (right-click) and the Command Palette under the **Clay** category. The active file must be saved before a preview runs.

| Command | CLI equivalent | Description |
| --- | --- | --- |
| **Clay: Preview template output** | `clay preview --template-only --file …` | Applies `brick-gen.json` transforms and annotation resolution. Mustache tags remain in the output. |
| **Clay: Preview generated output** | `clay preview --vars … --file …` | Full Mason rendering. Prompts for brick variables (from `brick.yaml`) and file-level Mustache variables, then shows a diff against the saved reference file. |

Generated preview remembers variable values per brick scope for the current VS Code session.

### Editor features

- **Syntax highlighting** — annotation markers inside comments via TextMate grammar injection.
- **Block shading** — tinted ranges for remove, replace, insert, partial, mustache, and spacing markers.
- **Code folding** — collapsible regions for remove, replace, and partial blocks.
- **Configurable colors** — override shading and marker colors under `clay.colors.*` (see below).

---

## Settings

| Setting | Description |
| --- | --- |
| `clay.cliPath` | Path to the `clay` executable. When empty, the extension searches `PATH`, the Dart install bin directory, the pub-cache bin directory, and the workspace `packages/clay_cli` script. |

### Annotation colors

Block shading and marker foreground colors are configurable under `clay.colors.*`. Values accept any CSS color string (hex, `rgb()`, `rgba()`, etc.). Changes apply immediately without reloading the window.

| Setting | Default | Applies to |
| --- | --- | --- |
| `clay.colors.remove.markerForeground` | `#F48771` | Remove, drop, and remove-boundary markers |
| `clay.colors.remove.contentBackground` | `rgba(244, 135, 113, 0.14)` | Content removed at generation time |
| `clay.colors.replace.boundaryMarkerForeground` | `#E5A84B` | `replace-start` and `replace-end` markers |
| `clay.colors.replace.withMarkerForeground` | `#4EC9B0` | `with` marker inside replace blocks |
| `clay.colors.replace.originalBackground` | `rgba(229, 168, 75, 0.14)` | Scaffold content replaced at generation time |
| `clay.colors.replace.replacementBackground` | `rgba(78, 201, 176, 0.14)` | Replacement content kept after generation |
| `clay.colors.insert.markerForeground` | `#C586C0` | Insert-block boundary markers |
| `clay.colors.insert.contentBackground` | `rgba(197, 134, 192, 0.14)` | Content inserted at generation time |
| `clay.colors.partial.markerForeground` | `#569CD6` | Partial-block boundary markers |
| `clay.colors.partial.payloadBackground` | `rgba(86, 156, 214, 0.14)` | Partial payload extracted to a `.partial` file |
| `clay.colors.mustache.tagForeground` | `#C678DD` | Mustache variable tags in annotation comments |
| `clay.colors.mustache.commentBackground` | `rgba(198, 120, 221, 0.10)` | Mustache tag spans in annotation comments |
| `clay.colors.mustache.dropFlagForeground` | `#F48771` | `x` whitespace-control flags on Mustache tags |
| `clay.colors.spacing.markerForeground` | `#A0A1A7` | Spacing-group (`w … w`) markers |
| `clay.colors.spacing.markerBackground` | `rgba(160, 161, 167, 0.12)` | Spacing-group marker spans |

Syntax highlighting colors for annotation markers are contributed via TextMate scopes in `package.json` (`configurationDefaults`). Use VS Code's `editor.tokenColorCustomizations` to override those scopes if needed.

---

## License

MIT — see [`package.json`](./package.json).
