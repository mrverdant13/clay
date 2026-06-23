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


| Layer         | Location                                           | Notes                                                          |
| ------------- | -------------------------------------------------- | -------------------------------------------------------------- |
| Unit tests    | `packages/clay_core/test/`                         | Annotation transforms, config parsing, `ignore` matching       |
| Command tests | `packages/clay_cli/test/`                          | Args parsing, exit codes, stderr formatting                    |
| Fixture tests | `packages/clay_cli/test/` or dedicated fixture dir | Golden `clay gen` output for representative reference projects |
| E2E           | `packages/clay_core/e2e/`                          | Public API integration (gen, validate, preview)                |
| E2E           | `packages/clay_cli/e2e/`                           | Full CLI invocations                                           |
| Unit          | `extensions/clay/test/`                            | Fast mocked module tests (`pnpm test`)                         |
| E2E           | `extensions/clay/e2e/`                             | Extension Development Host integration (`pnpm test:e2e`)       |


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


| Type       | Use for                                        |
| ---------- | ---------------------------------------------- |
| `chore`    | Setup, infrastructure, maintenance             |
| `ci`       | CI/CD workflow changes                         |
| `docs`     | Documentation-only changes                     |
| `feat`     | New user-facing functionality                  |
| `fix`      | Bug fixes                                      |
| `refactor` | Internal code changes without behavior changes |
| `test`     | Test additions or updates                      |


### Scopes

Use scopes for changes tied to a specific package or area:


| Scope                | Area                                       |
| -------------------- | ------------------------------------------ |
| `clay_core`          | Core library (`packages/clay_core`)        |
| `clay_cli`           | Dart CLI and library (`packages/clay_cli`) |
| `clay_vsc_extension` | VS Code extension (`extensions/clay`)      |


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


| Package     | Manifest                          | Runtime constant                            |
| ----------- | --------------------------------- | ------------------------------------------- |
| `clay_core` | `packages/clay_core/pubspec.yaml` | `clayCoreVersion` in `lib/src/version.dart` |
| `clay_cli`  | `packages/clay_cli/pubspec.yaml`  | `packageVersion` in `lib/src/version.dart`  |


**Release invariants:**

- **One package per release PR** — a `clay_core` release touches only `packages/clay_core/**`; a `clay_cli` release touches only `packages/clay_cli/**` (plus any `clay_core:` constraint update in that same package's `pubspec.yaml`).
- **Tag before OIDC publish** — merging a release PR automatically pushes annotated tag `<package>/<version>` on the merge commit via [Release tag on merge](.github/workflows/release-tag.yaml). Live pub.dev publishes dispatch manually on that **tag ref** (OIDC requires a tag, not a branch).
- **Poll after publish** — the publish workflow polls pub.dev until the version appears before the job succeeds.
- **No permanent tag for failed publishes** — if publish or the pub.dev poll fails, the publish workflow deletes the release tag; recreate it with [Release tag on merge](.github/workflows/release-tag.yaml) (`workflow_dispatch` fallback) before retrying publish.
- **Release order** — when both packages change, publish **`clay_core` first**, then **`clay_cli`** (the CLI depends on core at runtime and in `pubspec.yaml`).
- **Explicit publish opt-in** — live pub.dev publishes require a manual **Publish Dart package** workflow dispatch with `dry_run: false` on the matching tag ref; nothing publishes automatically on merge to `main`.

### pub.dev automated publishing setup (maintainers)

Live pub.dev publishes use **GitHub OIDC** via [`dart-lang/setup-dart@v1`](https://github.com/dart-lang/setup-dart) — no long-lived publish tokens. Complete this one-time setup **for each publishable package** on [pub.dev](https://pub.dev) → **Admin** → **Automated publishing** before the first OIDC publish. See [Dart automated publishing — configuring on pub.dev](https://dart.dev/tools/pub/automated-publishing#configuring-automated-publishing-from-github-actions-on-pubdev).

| Package     | pub.dev package | Tag pattern on pub.dev |
| ----------- | --------------- | ---------------------- |
| `clay_core` | `clay_core`     | `clay_core/{{version}}` |
| `clay_cli`  | `clay_cli`      | `clay_cli/{{version}}` |

For **each** row above, on that package's pub.dev admin page:

1. Enable **Publishing from GitHub Actions**.
2. Set **Repository** to `mrverdant13/clay` (this monorepo).
3. Set **Tag pattern** to the exact pattern in the table — Clay uses `<package>/<version>` tags (for example `clay_core/0.0.1-dev.2`), **not** `v{{version}}`.
4. Enable **Publishing from `workflow_dispatch` events** — required because live publishes are dispatched manually on a **tag ref** after [Release tag on merge](.github/workflows/release-tag.yaml) pushes `<package>/<version>` on the merge commit (pub.dev rejects branch-based OIDC; see [pub-dev #8507](https://github.com/dart-lang/pub-dev/issues/8507)).
5. Optionally enable **Require GitHub Actions environment** and name it `pub-dev-publish` to align with the existing GitHub environment protection rules on the publish workflow.

**Prerequisite:** Both packages must show automated publishing configured on pub.dev before dispatching a live OIDC publish. After the first successful OIDC publish, remove the legacy `PUB_CREDENTIALS` secret from the `pub-dev-publish` GitHub environment if it is still present — OIDC short-lived tokens replace it.

Further reading: [Dart automated publishing](https://dart.dev/tools/pub/automated-publishing), [Dart publishing from CI](https://dart.dev/tools/pub/publishing#publishing-from-a-ci-system), [GitHub Actions — manually running a workflow on a tag ref](https://docs.github.com/en/actions/using-workflows/manually-running-a-workflow).

### CI release workflows

Regular [Dart CI](.github/workflows/ci.yaml) runs format, analyze, and tests on every PR — it does not run `release.check` or publish. Release automation uses four dedicated workflows:


| Workflow                                                                   | Trigger                                                | Purpose                                                                                              |
| -------------------------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------------------------------------------------------- |
| **[Prepare Dart package release](.github/workflows/prepare-release.yaml)** | `workflow_dispatch` — choose `clay_core` or `clay_cli` | Runs scoped `release.prepare`, pushes `<package>/chore/release-<version>`, and opens a release PR    |
| **[Dart release PR check](.github/workflows/release-pr.yaml)**             | Pull request to `main` when release manifests change   | Runs `MELOS_PACKAGES`-scoped `release.check` when the PR title and branch match the release pattern  |
| **[Release tag on merge](.github/workflows/release-tag.yaml)**             | Merged release PR to `main`; optional `workflow_dispatch` | Creates and pushes annotated tag `<package>/<version>` on the merge commit (or recreates a missing tag on `main`) |
| **[Publish Dart package](.github/workflows/publish.yaml)**                 | `workflow_dispatch` — choose package and `dry_run`     | Pre-publish gate (`dry_run: true`) or OIDC live publish + pub.dev poll + tag verify (`dry_run: false` on the matching tag ref) |


Live publishes use the **`pub-dev-publish`** GitHub environment with OIDC authentication via [`dart-lang/setup-dart@v1`](https://github.com/dart-lang/setup-dart). Configure [environment protection rules](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment#environment-protection-rules) (for example required reviewers). See [Dart automated publishing](https://dart.dev/tools/pub/automated-publishing) for pub.dev admin setup and [pub.dev automated publishing setup (maintainers)](#pubdev-automated-publishing-setup-maintainers) above.

### Release runbook

1. **Prepare commits on `main`.** Ensure merged work uses [Conventional Commits](#commit-conventions) with the correct scopes (`clay_core`, `clay_cli`) so the prepare tool can include them in the changelog.
2. **Prepare the release.** Run **Actions → Prepare Dart package release**, choose `clay_core` or `clay_cli`. The workflow runs `MELOS_PACKAGES=<package> melos run release.prepare`, which invokes [`tool/prepare_package_release.dart`](tool/prepare_package_release.dart) with `--bump build` (increments `-dev.N` only), prepends a changelog from scoped commits since the latest package tag, syncs `version.dart`, then commits `pubspec.yaml`, `CHANGELOG.md`, and `lib/src/version.dart` under that package. It pushes `<package>/chore/release-<version>` and opens a PR titled `chore(<package>): release <version>`.
   - **Local writes:** `MELOS_PACKAGES=<package> melos run release.prepare` (same entry point as CI; git commit is manual locally).
   - **Local preview (dry-run):** invoke the prepare tool directly without `--apply` (default is dry-run):
     ```bash
     dart run tool/prepare_package_release.dart \
       --cwd packages/clay_core \
       --tag-format '{name}/{version}' \
       --commit-types feat,fix,docs,refactor,test,build \
       --bump build
     ```
   - **Semver segment bumps** (`patch`, `minor`, `major`) or an exact version require invoking the prepare tool directly with `--bump patch|minor|major` or `--version <semver>` (dry-run first; add `--apply` to write). See [Prepare tool flags](#prepare-tool-flags).
3. **Review the release PR.** One package per PR — do not combine `clay_core` and `clay_cli`. For `clay_cli` releases after a new `clay_core`, push a follow-up commit on the release branch updating the `clay_core:` minimum constraint (for example `clay_core: ^0.0.1-dev.2`) before merge — the prepare workflow does not auto-bump dependent packages.
4. **Wait for release PR CI.** [Dart release PR check](.github/workflows/release-pr.yaml) runs `MELOS_PACKAGES`-scoped `release.check` when the PR title, branch name, and changed release manifests all match. CI fails if more than one publishable package's manifests change in the same PR.
5. **Merge the release PR** into `main`. [Release tag on merge](.github/workflows/release-tag.yaml) automatically creates and pushes annotated tag `<package>/<version>` on the merge commit.
6. **Publish to pub.dev.** Run **Actions → Publish Dart package**, choose **Use workflow from: Tags**, select tag ref `<package>/<version>`, choose the target package, set `dry_run: false`, and approve the `pub-dev-publish` environment. The workflow verifies the release tag on `HEAD`, publishes via OIDC (`dart pub publish --force`), polls pub.dev until the version appears ([`tool/wait_for_pub_dev_version.dart`](tool/wait_for_pub_dev_version.dart)), and confirms the tag is still on `HEAD` — it does **not** create a new tag.
   - **Failure recovery:** If publish or the pub.dev poll fails, the workflow deletes the release tag. Fix the issue, run **Actions → Release tag on merge** with `workflow_dispatch` to recreate the tag on `main`, then dispatch publish again on that tag ref.
   - **Pre-publish gate:** To run `release.check` outside a release PR, dispatch the same workflow with `dry_run: true` (the default) from `main` or a tag ref. That runs `release.check` only — no pub.dev publish.
7. **Release order.** When both packages release, prepare and publish **`clay_core` first**, then **`clay_cli`**.

### How CI scopes `release.check`

`release.check` is a composite Melos script: its `steps:` invoke nested `melos run` commands (`test.ci`, `pub-score.local`, publish dry-run, and others). CI sets `MELOS_PACKAGES=<package>` on the job environment so every nested Melos step scopes to the releasing package. Passing `--scope` on the outer command would **not** propagate to those nested steps.

`format.ci` and `analyze.ci` inside `release.check` still validate the **whole workspace** (`dart format .` / `dart analyze .` at the repo root). Only Melos `exec` / filtered steps (`test.ci`, `pub-score.local`, publish dry-run) honor `MELOS_PACKAGES`.

Further reading: [Melos environment variables — `MELOS_PACKAGES](https://melos.invertase.dev/environment-variables#melos_packages)`.

### Version sync

Melos `version` and the sync script keep `pubspec.yaml` and `version.dart` aligned. During `release.prepare`, the Melos `preCommit` hook runs `tool/sync_package_version.dart` for each scoped publishable package before creating per-package release commits.

```bash
dart run tool/sync_package_version.dart --package clay_core
dart run tool/sync_package_version.dart --package clay_cli
```

Unit tests in each package fail CI when the manifest and constant diverge. Run the sync script manually if you change `version:` in `pubspec.yaml` outside `melos version`.

### Melos version flags

`release.prepare` passes flags required for **independent** dev releases in this monorepo:


| Flag                        | Why                                                                                                                           |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `--no-git-commit-version`   | The Melos `preCommit` hook syncs `version.dart` and creates per-package commits — Melos does not commit on its own.          |
| `--no-git-tag-version`      | [Release tagging](#release-tagging) creates tags when the release PR merges — not when Melos commits the version bump.        |
| `--no-dependent-versions`   | Bumping `clay_core` must not auto-bump `clay_cli` when only core is releasing. Bump the CLI in its own release PR when ready. |
| `--preid=dev`               | Pre-1.0 preview releases use `-dev.N` build identifiers.                                                                      |
| `--yes`                     | Non-interactive confirmation for CI and automated prepare-release runs.                                                       |
| `--manual-version=…`        | Select `build`, `patch`, `minor`, `major`, or an exact version per package.                                                   |


Melos also keeps `--dependent-constraints` enabled by default so a `clay_cli` release can update its `clay_core:` minimum when needed.

Further reading: [Melos `version` command](https://melos.invertase.dev/commands/version), [Melos automated releases guide](https://melos.invertase.dev/guides/automated-releases).

---

## Release tagging

Published packages in this monorepo are tagged **independently** — one git tag per package release. **[Release tag on merge](.github/workflows/release-tag.yaml)** creates and pushes an annotated tag when a release PR merges to `main`. **[Publish Dart package](.github/workflows/publish.yaml)** verifies that tag on `HEAD` before and after OIDC publish; it does not create tags.

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

- Tag the merge commit that contains the version bump for that package — [Release tag on merge](.github/workflows/release-tag.yaml) does this automatically when a release PR merges.
- The tag version must match the published artifact version exactly.
- Create an **annotated** tag with a short message naming the package and version.
- Tags mark the release commit **before** OIDC publish — dispatch **Publish Dart package** on that tag ref for live pub.dev uploads.
- The publish workflow polls pub.dev before the job succeeds — a successful publish confirms the version is listed on pub.dev.
- If publish or the poll fails, the publish workflow deletes the release tag — recreate it via [Release tag on merge](.github/workflows/release-tag.yaml) (`workflow_dispatch` on `main`) before retrying.
- One package per release PR; only tag the package released in that PR.

### Manual recovery

When a release tag is missing and must be recreated on `main`:

**Primary — workflow dispatch.** Run **Actions → [Release tag on merge](.github/workflows/release-tag.yaml)** → **Run workflow** on branch `main`, select `clay_core` or `clay_cli`. This creates annotated tag `<package>/<version>` on the current `main` commit, where `<version>` comes from that package's `pubspec.yaml`.

**Optional — local verify or dry-run** (does not create tags):

```bash
# Same annotated-tag-on-HEAD check the publish workflow runs
dart run tool/release_tag.dart --package clay_core --verify

# Print planned git tag / git push commands without mutating git
dart run tool/release_tag.dart --package clay_core
```

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


| Artifact                                       | Audience                                    | Status    |
| ---------------------------------------------- | ------------------------------------------- | --------- |
| `[README.md](README.md)`                       | Users — install, quick start, CLI reference | This repo |
| `[CONTRIBUTING.md](CONTRIBUTING.md)`           | Contributors — this guide                   | This repo |
| `[doc/annotations.md](doc/annotations.md)`     | Reference authors — marker syntax           | Available |
| `[doc/clay.schema.json](doc/clay.schema.json)` | Tooling — JSON schema for `clay.yaml`       | Available |
| `extensions/clay/README.md`                    | Extension users — setup and settings        | Available |
| `CHANGELOG.md`                                 | Release notes                               | Planned   |


When adding user-facing behavior, update `README.md` and plan corresponding entries in `doc/` or package changelogs.

---

## Questions

Open an issue for bugs, parity gaps, or design questions. For behavior changes, update `README.md`, `doc/`, and this guide in the same PR so user and contributor docs stay in sync.
