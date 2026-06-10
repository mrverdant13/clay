# Clay — VS Code extension

Editor support for [Clay](https://github.com/mrverdant13/clay) annotation markers in reference projects. The extension complements the [`clay`](../../packages/clay_cli/) CLI by providing in-editor tooling for authoring Mason brick templates from runnable reference code.

> **Status:** Early development. Annotation syntax highlighting, block shading, code folding, preview commands, and configurable annotation colors are available.

---

## Prerequisites

- **VS Code** 1.85 or newer
- **Node.js** 20.x
- **pnpm** 9.x — [installation guide](https://pnpm.io/installation), or:
  ```bash
  corepack enable
  corepack prepare pnpm@9 --activate
  ```
- **`clay` CLI** — required for preview commands. During monorepo development, run the CLI from the repo root:
  ```bash
  dart run packages/clay_cli/bin/clay.dart --version
  ```

---

## Installation (development)

From the repository root:

```bash
cd extensions/clay
pnpm install
pnpm run compile
```

To launch the extension in an Extension Development Host, open the **clay** repo in VS Code and choose **Run Clay Extension** from the Run and Debug panel (see [`.vscode/launch.json`](../../.vscode/launch.json)).

---

## Settings

| Setting | Description |
| --- | --- |
| `clay.cliPath` | Path to the `clay` executable. When empty, the extension searches `PATH`, the Dart install bin directory, and the pub-cache bin directory. After `clay_cli` is published, install with `dart pub global activate clay_cli`. |

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

## Capabilities

- Annotation syntax highlighting (all marker types, three comment flavors)
- Block/range shading for remove, replace, insert, partial, mustache, and spacing markers
- Code folding for remove, replace, and partial annotation blocks
- **Clay: Preview template output** — annotations and `brick-gen.json` transforms only
- **Clay: Preview generated output** — full Mustache resolution with variable prompts
- Scope discovery via the nearest `brick-gen.json`
- Configurable annotation colors (`clay.colors.*`)

---

## Development

| Command | Purpose |
| --- | --- |
| `pnpm run compile` | One-off esbuild bundle to `out/extension.js` |
| `pnpm run watch` | Rebuild on source changes (used by the VS Code launch task) |
| `pnpm test` | Compile smoke test and grammar validation |
| `pnpm run package` | Compile and produce a `.vsix` via `@vscode/vsce` |

Source lives under `src/`. TypeScript is bundled with esbuild; `vscode` is marked external and provided by the host at runtime.

---

## License

MIT — see [`package.json`](./package.json).
