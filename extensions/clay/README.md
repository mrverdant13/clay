# Clay — VS Code extension

Editor support for [Clay](https://github.com/mrverdant13/clay) annotation markers in reference projects. The extension complements the [`clay`](../../packages/clay_cli/) CLI by providing in-editor tooling for authoring Mason brick templates from runnable reference code.

---

## Prerequisites

- **VS Code** 1.85 or newer
- **`clay` CLI** `0.0.1-dev.2` or newer — required for preview commands (see [CLI setup](#cli-setup) below)

Preview compatibility checks delegate to the **`clay compat`** subcommand. Older CLI builds that predate `clay compat` are not supported for preview gating.

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

The Clay extension is **not yet listed** on the [Visual Studio Marketplace](https://marketplace.visualstudio.com/). Until it is published as **`mrverdant13.clay`**, install from a VSIX ([From a VSIX](#from-a-vsix)) or run it in the [Extension Development Host](#development-extension-development-host).

[`clay_cli`](https://pub.dev/packages/clay_cli) **`0.0.1-dev.2`** or newer is live on pub.dev and is the minimum CLI version for preview commands in this extension preview (includes `clay compat`).

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

Preview commands spawn the `clay` CLI. Before each preview, the extension runs **`clay compat`** against the discovered `clay.yaml` to verify `environment.clay`; only when that probe exits `0` does preview proceed. Non-zero stderr from `clay compat` is shown as an error and preview is not started.

The extension resolves an executable in this order:

1. **`clay.cliPath`** — when set in workspace or user settings, this path is tried first.
2. **`clay`** on `PATH`.
3. **Dart install bin** — platform-specific default location under the Dart SDK install.
4. **Pub-cache bin** — `~/.pub-cache/bin/clay` (or `%LOCALAPPDATA%\Pub\Cache\bin\clay.bat` on Windows).
5. **Workspace package** — when a workspace folder contains `packages/clay_cli/bin/clay.dart`, the extension runs `dart run` against that script automatically.

During monorepo development, open the clay repository (or any workspace that includes `packages/clay_cli`) and preview commands work without extra configuration.

Install [`clay_cli`](https://pub.dev/packages/clay_cli) **`0.0.1-dev.2`** or newer from pub.dev (includes `clay compat`):

```bash
dart install clay_cli
```

Ensure the pub-cache `bin` directory is on your `PATH`, or set `clay.cliPath` to the absolute path of the `clay` executable.

Verify the CLI is available and supports compatibility checks:

```bash
clay compat --help
# or, during development:
dart run packages/clay_cli/bin/clay.dart compat --help
```

---

## Using the extension

### Open a reference project

Open a folder that contains a `clay.yaml` config and a reference tree (see the [root README](../../README.md) for a typical layout). The extension discovers scope by walking up from the active file to the nearest `clay.yaml`, then verifying the file lies under the configured `reference` path.

Preview commands and scope-dependent features require a valid brick scope. If a file is outside every configured reference root, the extension shows a warning and does not run the CLI.

### Supported file types

Annotation highlighting, folding, shading, and preview commands apply to:

| Kind         | Extensions / names            | Comment flavor |
| ------------ | ----------------------------- | -------------- |
| Dart         | `.dart`                       | C-style `/* … */` |
| Shell        | `.sh`                         | Hash `# … #` |
| YAML         | `.yaml`, `.yml`               | Hash `# … #` |
| HTML / XML   | `.html`, `.htm`, `.xml`       | HTML `<!-- … -->` |
| Markdown     | `.md`, `.markdown`            | HTML `<!-- … -->` |
| Ignore files | `.gitignore`, `.dockerignore` | Hash `# … #` |

Use the comment flavor that matches the file. The same marker **keywords** work in every flavor — only the delimiters change.

### Annotation marker syntax

Markers are comment tokens that Clay resolves during `clay gen`. The extension highlights, shades, and folds the same marker set the CLI understands.

| Marker (C-style) | What it does | Editor treatment |
| --- | --- | --- |
| `drop` | Remove from marker to EOF | Red marker; content below shaded as removed |
| `remove-start` / `remove-end` | Remove a block | Red markers; block content shaded as removed |
| `replace-start` / `with` / `replace-end` | Replace scaffold with template lines | Orange boundaries; `with` in teal; scaffold vs replacement shading |
| `insert-start` / `insert-end` | Insert template lines | Purple markers; inserted content shaded |
| `{{…}}` in comment | Unwrap Mustache tag | Purple tag; optional `x` drop flags in red |
| `w <actions> w` | Expand `Nv` newlines / `N>` spaces | Gray marker highlight |
| `partial v <name>` / `partial ^ <name>` | Extract Mason partial | Blue markers; payload shaded |

**Flavor equivalents** for `remove-start` / `remove-end`:

```
/*remove-start*/ … /*remove-end*/       # Dart, JS, TS, …
#remove-start# … #remove-end#           # Shell, YAML, gitignore, …
<!--remove-start--> … <!--remove-end--> # HTML, Markdown, XML
```

Replace and insert blocks emit template lines with a comment prefix plus a space (`// `, `# `, or `<!-- `). The prefix is stripped at generation time.

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

In the editor, hash remove markers (`#remove-start#`, `#x-remove-start#`) appear in red with shaded removed content; replace blocks use orange boundaries with a teal `with` marker and distinct scaffold vs replacement shading; Mustache sections inside `# … #` comments are highlighted in purple. **Clay: Preview template output** resolves markers the same way `clay preview --template-only` does — leaving `{{package_name.snakeCase()}}` and `{{#use_code_generation}}` sections for Mason.

**Validate before generating** — run `clay validate` (or use preview commands, which also run `clay compat`) to catch unmatched markers. Structural rules cover remove, insert, replace, and partial blocks.

Full syntax, whitespace flags (`x-`, `-x`, `with iN`), and worked examples:
[Annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md).

### Preview commands

Both commands are available from the editor context menu (right-click) and the Command Palette under the **Clay** category. The active file must be saved before a preview runs. Each command first runs `clay compat` for the current brick scope; version or config errors from the CLI block preview before `clay preview` is spawned.

| Command                            | CLI equivalent                          | Description                                                                                                                                                  |
| ---------------------------------- | --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Clay: Preview template output**  | `clay preview --template-only --file …` | Applies `clay.yaml` transforms and annotation resolution. Mustache tags remain in the output.                                                                |
| **Clay: Preview generated output** | `clay preview --vars … --file …`        | Full Mason rendering. Prompts for brick variables (from `brick.yaml`) and file-level Mustache variables, then shows a diff against the saved reference file. |

Generated preview remembers variable values per brick scope for the current VS Code session.

### Editor features

- **Syntax highlighting** — annotation markers inside comments via TextMate grammar injection.
- **Block shading** — tinted ranges for remove, replace, insert, partial, mustache, and spacing markers.
- **Code folding** — collapsible regions for remove, replace, and partial blocks.
- **Configurable colors** — override shading and marker colors under `clay.colors.*` (see below).

---

## Settings

| Setting        | Description                                                                                                                                                                          |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `clay.cliPath` | Path to the `clay` executable. When empty, the extension searches `PATH`, the Dart install bin directory, the pub-cache bin directory, and the workspace `packages/clay_cli` script. |

### Annotation colors

Block shading and marker foreground colors are configurable under `clay.colors.*`. Values accept any CSS color string (hex, `rgb()`, `rgba()`, etc.). Changes apply immediately without reloading the window.

| Setting                                        | Default                     | Applies to                                     |
| ---------------------------------------------- | --------------------------- | ---------------------------------------------- |
| `clay.colors.remove.markerForeground`          | `#F48771`                   | Remove, drop, and remove-boundary markers      |
| `clay.colors.remove.contentBackground`         | `rgba(244, 135, 113, 0.14)` | Content removed at generation time             |
| `clay.colors.replace.boundaryMarkerForeground` | `#E5A84B`                   | `replace-start` and `replace-end` markers      |
| `clay.colors.replace.withMarkerForeground`     | `#4EC9B0`                   | `with` marker inside replace blocks            |
| `clay.colors.replace.originalBackground`       | `rgba(229, 168, 75, 0.14)`  | Scaffold content replaced at generation time   |
| `clay.colors.replace.replacementBackground`    | `rgba(78, 201, 176, 0.14)`  | Replacement content kept after generation      |
| `clay.colors.insert.markerForeground`          | `#C586C0`                   | Insert-block boundary markers                  |
| `clay.colors.insert.contentBackground`         | `rgba(197, 134, 192, 0.14)` | Content inserted at generation time            |
| `clay.colors.partial.markerForeground`         | `#569CD6`                   | Partial-block boundary markers                 |
| `clay.colors.partial.payloadBackground`        | `rgba(86, 156, 214, 0.14)`  | Partial payload extracted to a `.partial` file |
| `clay.colors.mustache.tagForeground`           | `#C678DD`                   | Mustache variable tags in annotation comments  |
| `clay.colors.mustache.commentBackground`       | `rgba(198, 120, 221, 0.10)` | Mustache tag spans in annotation comments      |
| `clay.colors.mustache.dropFlagForeground`      | `#F48771`                   | `x` whitespace-control flags on Mustache tags  |
| `clay.colors.spacing.markerForeground`         | `#A0A1A7`                   | Spacing-group (`w … w`) markers                |
| `clay.colors.spacing.markerBackground`         | `rgba(160, 161, 167, 0.12)` | Spacing-group marker spans                     |

Syntax highlighting colors for annotation markers are contributed via TextMate scopes in `package.json` (`configurationDefaults`). Use VS Code's `editor.tokenColorCustomizations` to override those scopes if needed.

---

## Troubleshooting

| Symptom                                                        | Likely cause                                                  | What to try                                                                                                              |
| -------------------------------------------------------------- | ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| "The clay CLI was not found"                                   | No executable on `PATH` and no workspace script               | Install or activate `clay_cli` (`0.0.1-dev.2`+), set `clay.cliPath`, or open a workspace that contains `packages/clay_cli`. |
| Preview blocked with a Clay version message                    | Installed CLI does not satisfy `environment.clay` in `clay.yaml` | Update `environment.clay`, upgrade `clay_cli`, or align the CLI pointed to by `clay.cliPath`.                          |
| "The clay CLI was not found" after a global install            | Installed build lacks `clay compat` (pre-`0.0.1-dev.2`)       | Upgrade to `clay_cli` **`0.0.1-dev.2`** or newer; confirm with `clay compat --help`.                                     |
| "Could not find a brick scope"                                 | No `clay.yaml` above the file, or file is outside `reference` | Add or fix `clay.yaml`; ensure the open file is under the configured reference directory.                                |
| "Clay preview is only available for supported reference files" | Unsupported language or extension                             | Open a file listed in [Supported file types](#supported-file-types).                                                     |
| Preview shows stale output                                     | Unsaved editor buffer                                         | Save the file before running preview; the CLI reads from disk.                                                           |
| Generated preview missing variables                            | No `brick.yaml` next to the target directory                  | Ensure Mason `brick.yaml` exists adjacent to the template output path declared in `clay.yaml`.                           |
| Colors do not update                                           | Settings cached by VS Code                                    | Change any `clay.colors.*` value; the extension listens for configuration changes and refreshes decorations immediately. |

For CLI behavior, flags, and `clay.yaml` fields, see the [Clay README](https://github.com/mrverdant13/clay/blob/main/README.md) and [Annotation reference](https://github.com/mrverdant13/clay/blob/main/doc/annotations.md).

---

## Development

| Command            | Purpose                                                     |
| ------------------ | ----------------------------------------------------------- |
| `pnpm run compile` | One-off esbuild bundle to `out/extension.js`                |
| `pnpm run watch`   | Rebuild on source changes (used by the VS Code launch task) |
| `pnpm test`        | Compile smoke test, grammar validation, and unit tests      |
| `pnpm run package` | Compile and produce a `.vsix` via `@vscode/vsce`            |

Source lives under `src/`. TypeScript is bundled with esbuild; `vscode` is marked external and provided by the host at runtime.

Use `pnpm install --frozen-lockfile` in CI or when reproducing locked dependency trees. The **Extension CI** workflow runs `pnpm test` on every pull request.

Contributor setup for the full monorepo (Dart CLI, Melos, extension) is documented in [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

---

## License

MIT — see [`package.json`](./package.json).
