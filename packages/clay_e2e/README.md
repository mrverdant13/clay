# clay_e2e

End-to-end tests for the `clay` library. Tests call the public API directly
(config load, generation, validation, preview) and assert on outputs and golden
trees — no CLI subprocess.

Run from the repository root:

```bash
melos run test.e2e
```

## Layout

| Path | Purpose |
| --- | --- |
| `e2e/*_e2e_test.dart` | Config, flow, and integration parity tests |
| `e2e/helpers/` | Public-API wrappers, fixture loaders, golden comparison utilities |
| `e2e/fixtures/integration/<scope>/` | Self-contained parity fixtures per scope |

Each integration scope contains:

- `clay.yaml` — config committed with the fixture
- `reference/` — source tree passed to generation
- `expected/` — golden output tree after generation
- `preview/` — committed preview expectations (`.txt`)

## Fixture file extensions (`.ref` / `.golden`)

Reference and golden fixture files often contain clay template syntax (mustache
tags, annotation markers, and other content that is **not** valid Dart or YAML).
If those files used normal extensions (`.dart`, `.yaml`), `dart format` and
`dart analyze` would fail when run on this package.

Committed fixture files therefore use extra suffixes:

| Suffix | Role | Example on disk | Materialized path |
| --- | --- | --- | --- |
| `.ref` | Reference source copied into a temp working directory | `widget.dart.ref` | `widget.dart` |
| `.golden` | Golden output compared after generation | `widget.dart.golden` | `widget.dart` |

Other file types (`.sql`, `.html`, `.json`, `.txt`, partials) are stored with
their normal extensions when the content is already plain text.

### Adding or updating fixtures

1. **Reference sources** with template syntax → save as `<name>.<ext>.ref` under `reference/`.
2. **Golden outputs** for `.dart` and `.yaml` → save as `<name>.<ext>.golden` under `expected/`.
3. **Preview expectations** → save as `.txt` under `preview/` (unchanged).
4. Run `melos run test.e2e` to verify; run `melos run format` to confirm the new files are not picked up as source.

Path mapping is handled by `e2e/helpers/fixture_paths.dart`,
`integration_fixture.dart` (copy into working dirs), and
`compare_directory_trees.dart` (golden comparison). When adding a new formatted
file type, extend `goldenSuffixExtensions` in `fixture_paths.dart`.
