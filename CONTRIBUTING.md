# Contributing

Thank you for helping build Clay. This guide covers local development, testing expectations, and collaboration conventions for this repository.

---

## Local development

### Prerequisites

- **Dart SDK** — stable channel (3.x). [Install Dart](https://dart.dev/get-dart) or use Flutter's bundled SDK.
- **Melos** — workspace orchestration for this monorepo. Install globally:
  ```bash
  dart pub global activate melos
  ```
- **Git**

For VS Code extension work under `extensions/clay/`:

- **Node.js** 20.x (matches the Extension CI workflow)
- **pnpm** 9.x — [pnpm installation](https://pnpm.io/installation), or:
  ```bash
  corepack enable
  corepack prepare pnpm@9 --activate
  ```

Optional:

- **VS Code** — for extension development and manual smoke tests
- **coverde** — coverage reporting in CI (`dart pub global activate coverde`)

### Clone and bootstrap

```bash
git clone <repository-url>
cd clay
melos bootstrap
```

`melos bootstrap` links workspace packages and runs `pub get` across `packages/` and any Dart tooling packages.

For the VS Code extension:

```bash
cd extensions/clay
pnpm install
pnpm test
```

Use `pnpm install --frozen-lockfile` in CI or when reproducing locked dependency trees. The **Extension CI** workflow (`.github/workflows/extension.yaml`) runs `pnpm test` on every pull request.

### Repository layout

```
clay/
├── packages/
│   ├── clay/               # Core library (config, transforms, generation)
│   │   └── e2e/            # End-to-end library tests
│   ├── clay_cli/           # Publishable CLI
│   │   └── e2e/            # End-to-end CLI tests
├── extensions/
│   └── clay/               # VS Code extension (TypeScript)
├── doc/                    # User docs (annotations, JSON schema)
├── README.md               # User-facing overview
└── CONTRIBUTING.md         # This file
```

**Dependency direction** (do not invert):

```
bin/clay.dart → ClayCommandRunner → commands → clay (features → entities + utils)
extensions/clay → clay CLI (spawn) + clay.yaml discovery (TypeScript)
```

`clay_cli` must not depend on monorepo-specific packages or git subprocesses.

### Running the CLI during development

From the repo root:

```bash
dart run packages/clay_cli/bin/clay.dart --version
dart run packages/clay_cli/bin/clay.dart gen --cwd path/to/brick-project
```

The Clay VS Code extension should invoke `dart run` against the workspace package until `clay_cli` is published to pub.dev.

---

## Testing expectations

All behavior changes should include or update tests.

| Layer | Location | Notes |
| --- | --- | --- |
| Unit tests | `packages/clay_core/test/` | Annotation transforms, config parsing, `ignore` matching |
| Command tests | `packages/clay_cli/test/` | Args parsing, exit codes, stderr formatting |
| Fixture tests | `packages/clay_cli/test/` or dedicated fixture dir | Golden `clay gen` output for representative reference projects |
| E2E | `packages/clay_core/e2e/` | Public API integration (gen, validate, preview) |
| E2E | `packages/clay_cli/e2e/` | Full CLI invocations |
| Unit | `extensions/clay/test/` | Fast mocked module tests (`pnpm test`) |
| E2E | `extensions/clay/e2e/` | Extension Development Host integration (`pnpm test:e2e`) |

---

## Commit conventions

This repository uses [Conventional Commits](https://www.conventionalcommits.org/).

### Format

- Setup/infra work (no scope): `<type>: <description>`
- Scoped work (one area): `<type>(<scope>): <description>`
- Scoped work (multiple areas): `<type>(<scope1>,<scope2>): <description>`

Use a **single scope** when the change is confined to one package or area. Use **multiple comma-separated scopes** (no spaces) when a PR or commit intentionally spans more than one — for example, a CLI change plus the extension wiring that consumes it.

PR titles follow the same format as commit messages.

### Allowed types

| Type | Use for |
| --- | --- |
| `chore` | Setup, infrastructure, maintenance |
| `ci` | CI/CD workflow changes |
| `docs` | Documentation-only changes |
| `feat` | New user-facing functionality |
| `fix` | Bug fixes |
| `refactor` | Internal code changes without behavior changes |
| `test` | Test additions or updates |

### Scopes

Use scopes for changes tied to a specific package or area:

| Scope | Area |
| --- | --- |
| `clay_core` | Core library (`packages/clay_core`) |
| `clay_cli` | Dart CLI and library (`packages/clay_cli`) |
| `clay_vsc_extension` | VS Code extension (`extensions/clay`) |

For cross-cutting setup or CI-only changes, omit the scope: `chore: …`, `ci: …`, `docs: …`.

### Multiple scopes

When a change touches more than one scoped area, list every affected scope in parentheses, separated by commas:

```
feat(clay_cli,clay_vsc_extension): wire preview command through extension
fix(clay_cli,clay_vsc_extension): align preview output between CLI and extension
```

Guidelines:

- Include only scopes that are **meaningfully changed** — do not tag unrelated areas for visibility.
- Prefer **one scope** when one area owns the change and others only pick up generated artifacts or trivial updates.
- List scopes in **logical order** (primary area first, then dependents) or **alphabetically** within a PR; stay consistent across the commits in that PR.
- The **PR title** should use the same scoped format as the primary commit (or squash commit) when the PR spans multiple areas.

### Examples

```
chore: scaffold melos workspace and clay_cli package
ci: add analyze test and coverage workflow
feat(clay_cli): implement clay gen command
fix(clay_cli): resolve relative paths from project root
test(clay_cli): add annotation validator unit tests
feat(clay_vsc_extension): add annotation syntax highlighting
feat(clay_cli,clay_vsc_extension): expose preview CLI and invoke from extension
docs: document clay.yaml fields in README
```

---

## Pull request guidelines

- Keep PRs **atomic and reviewable** — one logical change per PR.
- Align the **PR title** with the main commit intent, using the same [Conventional Commits](#commit-conventions) format — including multiple scopes when the PR spans more than one area.
- Include **tests** for any behavior changes (unit, command, parity, or e2e as appropriate).
- Link related issues or milestone items when applicable.
- Do not commit secrets, `.env` files, or local editor state.
- For behavior-sensitive changes, note which fixture or sample project you validated against.

### Review checklist

- [ ] Behavior matches documented CLI and API contracts (or documents intentional deviation)
- [ ] Tests added or updated
- [ ] Formatting verified (`melos run format.ci`)
- [ ] Analysis verified (`melos run analyze.ci`)
- [ ] Tests verified (`melos run test.ci`)
- [ ] Extension tests verified (`cd extensions/clay && pnpm test`) when `extensions/clay/` changes
- [ ] No imports from external monorepo-internal packages in `clay` or `clay_cli`
- [ ] Public API changes reflected in `README.md` or `doc/` when user-facing

---

## Documentation

| Artifact | Audience | Status |
| --- | --- | --- |
| [`README.md`](README.md) | Users — install, quick start, CLI reference | This repo |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contributors — this guide | This repo |
| [`doc/annotations.md`](doc/annotations.md) | Reference authors — marker syntax | Available |
| [`doc/clay.schema.json`](doc/clay.schema.json) | Tooling — JSON schema for `clay.yaml` | Available |
| `extensions/clay/README.md` | Extension users — setup and settings | Available |
| `CHANGELOG.md` | Release notes | Planned |

When adding user-facing behavior, update `README.md` and plan corresponding entries in `doc/` or package changelogs.

---

## Questions

Open an issue for bugs, parity gaps, or design questions. For behavior changes, update `README.md`, `doc/`, and this guide in the same PR so user and contributor docs stay in sync.
