# Annotation reference

Clay turns reference projects into Mason brick templates by applying **annotations** — comment-based markers embedded in source files. During `clay gen`, markers are resolved and removed; the resulting files become the `__brick__` template tree.

This guide documents every supported marker type, the three equivalent comment flavors, and how transforms are ordered.

---

## Comment flavors

The same marker semantics work in three comment styles. Pick the flavor that matches the file you are editing.

| Flavor | Opening | Closing | Typical files |
| --- | --- | --- | --- |
| C-style | `/*` | `*/` | Dart, C, C++, Java, JavaScript, TypeScript |
| Hash | `#` | `#` | Shell, YAML, Ruby, Python (shebang-adjacent) |
| HTML | `<!--` | `-->` | HTML, XML, Markdown |

Marker names are identical across flavors — only the comment delimiters change. The tables below use **C-style** syntax; substitute `#` or `<!-- -->` delimiters for other flavors.

| C-style | Hash | HTML |
| --- | --- | --- |
| `/*marker*/` | `#marker#` | `<!--marker-->` |

---

## Transform pipeline

When Clay processes a reference file, transforms run in this fixed order:

1. **Line deletions** — ranges declared in `brick-gen.json` → `lineDeletions`
2. **Content replacements** — regex rules from `brick-gen.json` → `replacements`
3. **Remotions** — `drop` markers and `remove-start` / `remove-end` blocks
4. **Replace blocks** — `replace-start` / `with` / `replace-end`
5. **Insert blocks** — `insert-start` / `insert-end`
6. **Mustache unwrapping** — `{{…}}` tags inside comments
7. **Spacing groups** — `w <actions> w`
8. **Partials** — `partial v <name>` / `partial ^ <name>`

Binary files (`.png`, `.webp`) are copied without text transforms.

Use `clay preview --file <path>` to inspect the result for a single file, or `clay validate` to check marker pairing across the reference tree.

---

## Drop markers

A **drop** marker removes everything from the marker through the end of the file.

| Flavor | Marker |
| --- | --- |
| C-style | `/*drop*/` |
| Hash | `#drop#` |
| HTML | `<!--drop-->` |

**Reference (before `clay gen`):**

```dart
void main() {
  runApp(const MyApp());
}
/*drop*/
// Everything below is discarded at generation time.
void debugOnly() {}
```

**Template output:**

```dart
void main() {
  runApp(const MyApp());
}
```

Drop markers are useful for trailing development-only code, sample data, or scaffolding that should not appear in the generated brick.

---

## Remove blocks

**Remove blocks** delete a span of content between paired start and end markers. Use them when only a section of a file should be excluded from the template.

| Marker | Role |
| --- | --- |
| `remove-start` | Opens the block (content after this marker is removed) |
| `remove-end` | Closes the block |

**Reference:**

```dart
import 'package:flutter/material.dart';
/*remove-start*/
import 'package:flutter/foundation.dart'; // dev-only import
/*remove-end*/
import 'package:my_app/app.dart';
```

**Template output:**

```dart
import 'package:flutter/material.dart';
import 'package:my_app/app.dart';
```

### Whitespace control

Optional flags on remove markers control whether whitespace adjacent to the block is kept:

| Flag | Position | Effect |
| --- | --- | --- |
| `x-` | Prefix on `remove-start` (e.g. `/*x-remove-start*/`) | Drop leading whitespace before the block |
| `-x` | Suffix on `remove-end` (e.g. `/*remove-end-x*/`) | Drop trailing whitespace after the block |

When flags are absent, leading and trailing whitespace captured around the block is preserved in the output.

**Example with `x-` and `-x`:**

```dart
line   /*x-remove-start*/
removed content
/*remove-end-x*/    0
next line
```

**Template output:**

```dart
line0
next line
```

Remove blocks can span multiple lines. Start and end markers must use the same comment flavor and must be properly paired — `clay validate` reports unmatched markers.

---

## Replace blocks

**Replace blocks** substitute a region of reference code with new template content. They use three markers in sequence:

| Marker | Role |
| --- | --- |
| `replace-start` | Opens the block; content between start and `with` is discarded |
| `with` | Separates discarded reference content from replacement lines |
| `replace-end` | Closes the block |

Replacement lines inside the `with` section must use the **same comment flavor** as the block markers, with a single space after the comment opener:

| Flavor | Replacement line format |
| --- | --- |
| C-style | `// <content>` |
| Hash | `# <content>` |
| HTML | `<!-- <content>-->` |

**Reference:**

```dart
line/*replace-start*/
asdf
asdf asdf
/*with i0*/
// 1
// line2
/*replace-end*/
line3
```

**Template output:**

```dart
line1
line2
line3
```

### Indentation

Add `i<N>` to the `with` marker to indent every replacement line by `N` spaces:

```
/*with i2*/
// indented line
```

produces `  indented line` in the template. Omit `i<N>` (or use `i0`) for no extra indentation.

Replace blocks cannot be nested. `clay validate` reports missing `with` markers, duplicate `with` markers, and unmatched start/end pairs.

---

## Insert blocks

**Insert blocks** inject template content at a point in the file. Unlike replace blocks, there is no discarded reference region — only the lines between start and end markers matter.

| Marker | Role |
| --- | --- |
| `insert-start` | Opens the block |
| `insert-end` | Closes the block |

Lines between the markers must use the matching comment prefix (same rules as replace-block replacement lines). The comment prefix is stripped; only the inner content is emitted.

**Reference:**

```dart
line/*insert-start*/
// 1
// line2
/*insert-end*/
line3
```

**Template output:**

```dart
line1
line2
line3
```

Leading and trailing whitespace on each comment line is trimmed before the prefix is removed. Insert blocks cannot be nested; `clay validate` checks start/end pairing.
