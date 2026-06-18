# Contributing

Thank you for helping build Clay. This guide covers local development, testing expectations, and collaboration conventions for this repository.

---

## Local development

### Prerequisites

- **Dart SDK** — stable channel (3.x). [Install Dart](https://dart.dev/get-dart) or use Flutter's bundled SDK.
- **Melos** — workspace orchestration for this monorepo. Install globally:
  ```bash
  dart install melos
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
- **coverde** — coverage reporting in CI (`dart install coverde`)

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

## Dart package releases (`clay_core` and `clay_cli`)

Both publishable packages ship to [pub.dev](https://pub.dev) with per-package changelogs. Each package exposes a compile-time version constant that must stay in sync with its `pubspec.yaml`:

| Package | Manifest | Runtime constant |
| --- | --- | --- |
| `clay_core` | `packages/clay_core/pubspec.yaml` | `clayCoreVersion` in `lib/src/version.dart` |
| `clay_cli` | `packages/clay_cli/pubspec.yaml` | `packageVersion` in `lib/src/version.dart` |

**Release invariants:**

- **One package per release PR** — a `clay_core` release touches only `packages/clay_core/**`; a `clay_cli` release touches only `packages/clay_cli/**` (plus any `clay_core:` constraint update in that same package's `pubspec.yaml`).
- **Tag after publish** — never create `clay_core/<version>` or `clay_cli/<version>` tags until `dart pub publish` succeeds **and** pub.dev lists the version.
- **Release order** — when both packages change, publish **`clay_core` first**, then **`clay_cli`** (the CLI depends on core at runtime and in `pubspec.yaml`).
- **Explicit publish opt-in** — live pub.dev publishes require a manual **Publish Dart package** workflow dispatch with `dry_run: false`; nothing publishes automatically on merge to `main`.

### CI release workflows

Maintainers can run most of the release path from GitHub Actions. Regular [Dart CI](.github/workflows/ci.yaml) still runs format, analyze, and tests on every PR — it does not run `release.check` or publish.

| Workflow | Trigger | Purpose |
| --- | --- | --- |
| [**Prepare Dart package release**](.github/workflows/prepare-release.yaml) | `workflow_dispatch` — choose `clay_core` or `clay_cli` | Runs scoped `release.prepare`, pushes `<package>/chore/release-<version>`, and opens a release PR |
| [**Dart release PR check**](.github/workflows/release-pr.yaml) | Pull request to `main` when release manifests change | Runs `MELOS_PACKAGES`-scoped `release.check` when the PR title and branch match the release pattern |
| [**Publish Dart package**](.github/workflows/publish.yaml) | `workflow_dispatch` — choose package and `dry_run` | Pre-publish gate (`dry_run: true`) or live publish + pub.dev poll + annotated tag (`dry_run: false`) |

**Prepare release** (`prepare-release.yaml`) checks out `main`, runs `melos run release.prepare -- --scope=<package>` (Melos derives the next `-dev.N` bump from conventional commits), and opens a PR titled `chore(<package>): release <version>` on branch `<package>/chore/release-<version>`. It does not publish or tag. For `clay_cli` releases after a new `clay_core`, ensure the `clay_core:` constraint is updated on the release branch before merge — the prepare workflow does not auto-bump dependent packages.

**Release PR CI** (`release-pr.yaml`) runs only when **all** of the following hold:

1. The PR changes `packages/*/pubspec.yaml` or `packages/*/CHANGELOG.md` for a publishable package.
2. The PR title matches `chore(<package>): release <version>`.
3. The head branch is named `<package>/chore/release-<version>`.

CI fails if more than one publishable package's release manifests change in the same PR. When the guards pass, the workflow sets `MELOS_PACKAGES` and runs `melos run release.check`.

**Publish** (`publish.yaml`) always runs `release.check` in a `check` job. With `dry_run: true` (the default), the workflow stops there — no pub.dev publish, no git tag. With `dry_run: false`, a second job publishes via `dart pub publish --force`, waits for the version to appear on pub.dev ([`tool/wait_for_pub_dev_version.dart`](tool/wait_for_pub_dev_version.dart) polls the [pub.dev package API](https://pub.dev/api/packages/<name>)), then creates and pushes an annotated tag via [`tool/release_tag.dart`](tool/release_tag.dart). If the poll times out, the job fails **without** creating a tag.

Live publishes use the **`pub-dev-publish`** GitHub environment. Configure [environment protection rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-protection-rules) (for example required reviewers) and store [`PUB_CREDENTIALS`](https://dart.dev/tools/pub/publishing#publishing-from-a-ci-system) as an environment secret. See [Dart publishing from CI](https://dart.dev/tools/pub/publishing#publishing-from-a-ci-system) for credential setup.

### Step-by-step runbook

1. **Prepare commits on `main`.** Ensure merged work uses [Conventional Commits](#commit-conventions) with the correct scopes (`clay_core`, `clay_cli`) so Melos can generate changelog entries.

2. **Bump version and changelog** for the target package. Use **either** path:

   **Option A — locally:**

   ```bash
   # Dev build bump (Melos derives the next -dev.N from conventional commits)
   melos run release.prepare -- --scope=clay_core

   # Patch / minor / major when graduating beyond -dev.N
   melos run release.prepare -- --scope=clay_cli --manual-version=clay_cli:patch
   ```

   **Option B — GitHub Actions:** run **Actions → Prepare Dart package release**, choose `clay_core` or `clay_cli`. The workflow commits the version bump, pushes `<package>/chore/release-<version>`, and opens the release PR.

   `release.prepare` wraps `melos version` with `--no-git-tag-version`, `--no-dependent-versions`, and `--preid=dev`. A `preCommit` hook syncs `lib/src/version.dart` from each bumped `pubspec.yaml` (see [Version sync](#version-sync) below).

3. **Open or review the release PR.** The PR title must be `chore(<package>): release <version>` and the head branch `<package>/chore/release-<version>`. One package per PR — do not combine `clay_core` and `clay_cli` in the same release PR.

4. **Pre-publish checks.** [Dart release PR check](.github/workflows/release-pr.yaml) runs `MELOS_PACKAGES`-scoped `release.check` automatically when the PR matches the release title and branch pattern. Optionally run the gate locally before pushing:

   ```bash
   # Full gate for all publishable packages
   melos run release.check

   # Scoped to the package you are releasing
   MELOS_PACKAGES=clay_core melos run release.check
   MELOS_PACKAGES=clay_cli melos run release.check
   ```

   `release.check` runs format, analyze, test, pub score, and `melos publish --dry-run`. Use `MELOS_PACKAGES` for single-package release PRs — see [Why `MELOS_PACKAGES` and not `--scope`?](#why-melos_packages-and-not---scope) below. Regular PR CI still runs format, analyze, and tests; it does not replace `release.check` on non-release PRs.

   You can also dispatch **Publish Dart package** with `dry_run: true` to run the same gate outside a release PR.

5. **Merge the release PR** into `main`.

6. **Publish to pub.dev.** Prefer **Actions → Publish Dart package** with `dry_run: false` and the target package over a local publish:

   ```bash
   # CI path (recommended): workflow_dispatch with dry_run: false
   # Requires pub-dev-publish environment approval and PUB_CREDENTIALS secret
   ```

   Local fallback from the package directory on `main`:

   ```bash
   cd packages/clay_core   # or packages/clay_cli
   dart pub publish
   ```

   Alternatively, use `melos publish` without `--dry-run` from the repo root when publishing multiple packages in sequence (still one package at a time, `clay_core` before `clay_cli`).

7. **Tag after pub.dev confirms the version.** When publishing via **Publish Dart package** with `dry_run: false`, CI polls pub.dev and creates the annotated tag automatically. Manual fallback:

   ```bash
   melos run release.tag -- --package clay_core
   melos run release.tag -- --package clay_core --execute
   ```

   Or run the equivalent git commands manually (see [Release tagging](#release-tagging) below). **Do not tag** if publish failed or the version is not yet visible on pub.dev.

8. **When releasing `clay_cli` after a new `clay_core`**, bump the `clay_core:` minimum constraint in the same `clay_cli` release PR (for example `clay_core: ^0.0.1-dev.2`) before merge and `MELOS_PACKAGES=clay_cli melos run release.check`.

### Why `MELOS_PACKAGES` and not `--scope`?

`release.check` is a composite Melos script: its `steps:` invoke nested `melos run` commands (`test.ci`, `pub-score.local`, publish dry-run, and others). Passing `--scope` on the outer `melos run release.check` filters only that top-level invocation — it does **not** propagate to those nested steps. Setting `MELOS_PACKAGES=<package>` in the environment scopes every Melos workspace resolution in the process, including nested `melos run` calls inside `steps:` scripts.

Use `MELOS_PACKAGES` for single-package pre-publish checks. Reserve `--scope` for direct Melos commands (for example `melos run release.prepare -- --scope=clay_core …` or `melos run test.ci --scope=clay_core` when not going through a composite parent script).

`format.ci` and `analyze.ci` inside `release.check` still validate the **whole workspace** (`dart format .` / `dart analyze .` at the repo root). Only Melos `exec` / filtered steps (`test.ci`, `pub-score.local`, publish dry-run) honor `MELOS_PACKAGES`.

Further reading: [Melos environment variables — `MELOS_PACKAGES`](https://melos.invertase.dev/environment-variables#melos_packages).

### Version sync

Melos `version` and the sync script keep `pubspec.yaml` and `version.dart` aligned:

```bash
dart run tool/sync_package_version.dart --package clay_core
dart run tool/sync_package_version.dart --package clay_cli
```

Unit tests in each package fail CI when the manifest and constant diverge. Run the sync script manually if you change `version:` in `pubspec.yaml` outside `melos version`.

### Melos version flags

`release.prepare` passes flags required for **independent** dev releases in this monorepo:

| Flag | Why |
| --- | --- |
| `--no-git-tag-version` | [Release tagging](#release-tagging) requires tags **after** a successful publish, not when Melos commits the version bump. |
| `--no-dependent-versions` | Bumping `clay_core` must not auto-bump `clay_cli` when only core is releasing. Bump the CLI in its own release PR when ready. |
| `--preid=dev` | Pre-1.0 preview releases use `-dev.N` build identifiers. |
| `--manual-version=…` | Select `build`, `patch`, `minor`, `major`, or an exact version per package. |

Melos also keeps `--dependent-constraints` enabled by default so a `clay_cli` release can update its `clay_core:` minimum when needed.

Further reading: [Melos `version` command](https://melos.invertase.dev/commands/version), [Melos automated releases guide](https://melos.invertase.dev/guides/automated-releases).

---

## Release tagging

Published packages in this monorepo are tagged **independently** — one git tag per package release, created **after** the artifact is live (pub.dev or Visual Studio Marketplace).

### Format

```
<scope>/<version>
```

- **`<scope>`** — same scope names as [commit conventions](#scopes) (`clay_core`, `clay_cli`, `clay_vsc_extension`).
- **`<version>`** — exact version string from the package manifest (`pubspec.yaml` or `extensions/clay/package.json`). No `v` prefix.

### Examples

```
clay_core/0.0.1-dev.1
clay_cli/0.0.2
clay_vsc_extension/0.1.2
```

### Rules

- Tag the merge commit that contains the version bump for that package.
- The tag version must match the published artifact version exactly.
- Create an **annotated** tag with a short message naming the package and version.
- Do not tag before a successful publish — failed publishes should not leave orphan tags.
- One package per release PR; only tag the package that was published in that PR.

### Commands

After `clay_core` `0.0.1-dev.1` is live on pub.dev:

```bash
git tag -a clay_core/0.0.1-dev.1 -m "clay_core 0.0.1-dev.1"
git push origin clay_core/0.0.1-dev.1
```

Or use `melos run release.tag -- --package clay_core --execute` (see [Dart package releases](#dart-package-releases-clay_core-and-clay_cli)).

List tags for a package:

```bash
git tag -l 'clay_cli/*'
```

Checkout a release:

```bash
git checkout clay_core/0.0.1-dev.1
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
