# clay_cli example

Minimal `clay.yaml` project that exercises the `clay` CLI (`gen`, `validate`,
and `preview`). The reference tree contains one annotated Dart file with a path
rename (`ref_pkg` → `{{package_name}}`) and a `/*drop*/` line-deletion marker.

## Layout

```
example/
├── clay.yaml
├── reference/
│   └── lib/ref_pkg/greeting.dart.ref
└── brick/                  # created by `clay gen` (gitignored)
```

## Prerequisites

Install the CLI globally:

```bash
dart pub global activate clay_cli
```

Ensure `~/.pub-cache/bin` is on your `PATH`, then verify:

```bash
clay --version
```

When developing this repository locally, run the CLI with `dart run` from
`packages/clay_cli` instead of a global install (paths below use `../bin/clay.dart`).

## Generate a template

From this directory:

```bash
clay gen --cwd .
```

Local development:

```bash
dart run ../bin/clay.dart gen --cwd .
```

Clay copies `reference/` to `brick/`, renames `ref_pkg` to `{{package_name}}`,
and removes lines marked with `/*drop*/`. Stdout reports resolved paths and
the file count.

## Validate annotations

```bash
clay validate --cwd .
```

Local development:

```bash
dart run ../bin/clay.dart validate --cwd .
```

Exits with code `0` when the reference tree has no annotation issues.

## Preview a reference file

Template-only preview (Mustache tags left intact):

```bash
clay preview --cwd . --file lib/ref_pkg/greeting.dart.ref --template-only
```

Local development:

```bash
dart run ../bin/clay.dart preview --cwd . --file lib/ref_pkg/greeting.dart.ref --template-only
```

Expected stdout:

```dart
/// Greeting helpers for {{package_name}}.
String greeting(String name) => 'Hello, $name!';
```
