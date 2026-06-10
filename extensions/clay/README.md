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

## License

MIT — see [`package.json`](./package.json).
