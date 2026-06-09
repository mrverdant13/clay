# Clay — VS Code extension

Editor support for [Clay](https://github.com/mrverdant13/clay) annotation markers in reference projects. The extension complements the [`clay`](../../packages/clay_cli/) CLI by providing in-editor tooling for authoring Mason brick templates from runnable reference code.

> **Status:** Early development. Annotation syntax highlighting is available; preview commands, block shading, and folding land in follow-up work.

---

## Prerequisites

- **VS Code** 1.85 or newer
- **Node.js** 20.x
- **pnpm** 9.x — [installation guide](https://pnpm.io/installation), or:
  ```bash
  corepack enable
  corepack prepare pnpm@9 --activate
  ```
- **`clay` CLI** — required once preview commands ship. During monorepo development, run the CLI from the repo root:
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
| `clay.cliPath` | Path to the `clay` executable. When empty, the extension searches `PATH`, the Dart install bin directory, and `~/.pub-cache/bin`. After `clay_cli` is published, install with `dart pub global activate clay_cli`. |

Additional `clay.colors.*` settings for annotation shading will be added in a later release.

---

## Planned capabilities

- Annotation syntax highlighting (all marker types, three comment flavors) — **available**
- Block/range shading and code folding
- **Clay: Preview generated output** — full Mustache resolution with variable prompts
- **Clay: Preview template output** — annotations and `brick-gen.json` transforms only
- Scope discovery via the nearest `brick-gen.json`
- Configurable annotation colors

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
