# Annotation reference

Clay turns reference projects into Mason brick templates by applying **annotations** — comment-based markers embedded in source files. During `clay gen`, markers are resolved and removed; the resulting files become the `__brick__` template tree.

This guide documents every supported marker type, the three equivalent comment flavors, and how transforms are ordered.

---

## Syntax patterns

Every marker is a **comment** whose inner text follows a fixed keyword pattern. Clay never parses bare keywords in source code — only text inside a recognized comment delimiter.

| Pattern | Meaning |
| --- | --- |
| `<open><keyword><close>` | Single-token marker (e.g. `drop`, Mustache unwrap, spacing group) |
| `<open><keyword><close>` … `<open><keyword><close>` | Paired start/end block (remove, insert, partial) |
| `<open>replace-start<close>` … `<open>with[ iN]<close>` … `<open>replace-end<close>` | Three-part replace block |

General forms (substitute delimiters per flavor):

```
/*<marker>*/                    # single-token marker
/*<start>*/ … /*<end>*/         # paired block
/*replace-start*/ … /*with iN*/ … /*replace-end*/
```

**Rules that apply to all markers:**

- Marker keywords are **case-sensitive** and use **hyphenated** names (`remove-start`, not `removeStart`).
- Start and end markers in a block must use the **same comment flavor** (`/* */` with `/* */`, not `/* */` with `# #`).
- Markers are removed from template output; only the transformed content remains.
- Use `clay validate` to check structural pairing before generation, and `clay preview --file <path>` to inspect a single file's output.

---

## Comment flavors

The same marker semantics work in three comment styles. Pick the flavor that matches the file you are editing.

| Flavor | Opening | Closing | Typical files |
| --- | --- | --- | --- |
| C-style | `/*` | `*/` | `.dart`, `.js`, `.ts`, `.java`, `.c`, `.cpp` |
| Hash | `#` | `#` | `.sh`, `.yaml`, `.yml`, `.py`, `.rb`, `.gitignore` |
| HTML | `<!--` | `-->` | `.html`, `.xml`, `.md`, `.markdown` |

Marker names are identical across flavors — only the comment delimiters change. The tables below use **C-style** syntax; substitute `#` or `<!-- -->` delimiters for other flavors.

| C-style | Hash | HTML |
| --- | --- | --- |
| `/*marker*/` | `#marker#` | `<!--marker-->` |

**Per-flavor examples for `remove-start` / `remove-end`:**

| Flavor | Start | End |
| --- | --- | --- |
| C-style | `/*remove-start*/` | `/*remove-end*/` |
| Hash | `#remove-start#` | `#remove-end#` |
| HTML | `<!--remove-start-->` | `<!--remove-end-->` |

---

## Marker cheat sheet

All markers below are shown in C-style form. See [Comment flavors](#comment-flavors) to translate delimiters.

| Marker | Kind | Purpose |
| --- | --- | --- |
| `drop` | Single | Remove from marker through end of file |
| `remove-start` / `remove-end` | Paired | Remove a content block |
| `x-remove-start` / `remove-end-x` | Paired + flags | Remove block and adjacent whitespace |
| `replace-start` / `with` / `replace-end` | Triple | Replace scaffold with template lines |
| `with iN` | Modifier | Indent replacement lines by `N` spaces |
| `insert-start` / `insert-end` | Paired | Insert template lines at a position |
| `{{…}}` in comment | Single | Unwrap Mustache tag for Mason |
| `x` beside `{{…}}` | Flag | Drop whitespace before/after tag |
| `w <actions> w` | Single | Expand `Nv` newlines and `N>` spaces |
| `partial v <name>` / `partial ^ <name>` | Paired | Extract content into a `.partial` file |

Replace and insert blocks emit lines prefixed with the matching comment opener plus a space (`// `, `# `, or `<!-- `). See [Replace blocks](#replace-blocks) and [Insert blocks](#insert-blocks).

---

## Transform pipeline

When Clay processes a reference file, transforms run in this fixed order:

1. **Line deletions** — ranges declared in `clay.yaml` → `lineDeletions`
2. **Content replacements** — regex rules from `clay.yaml` → `replacements`
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

---

## Mustache unwrapping

Mason template variables use Mustache syntax (`{{variable}}`, `{{#section}}`, etc.). In reference files, wrap a tag in a comment so it is valid source code; Clay unwraps the comment during generation, leaving the Mustache tag in the template.

| Flavor | Example |
| --- | --- |
| C-style | `/*{{name}}*/` |
| Hash | `#{{name}}#` |
| HTML | `<!--{{name}}-->` |

**Reference:**

```dart
class /*{{class_name}}*/ MyReferenceClass {}
```

**Template output:**

```dart
class {{class_name}} MyReferenceClass {}
```

### Whitespace control

Optional `x` flags adjacent to the tag control whitespace on that side (similar to remove-block flags):

| Flag | Position | Effect |
| --- | --- | --- |
| `x` | Before the tag inside the opener (e.g. `/*x{{tag}}*/`) | Drop leading whitespace before the tag |
| `x` | After the tag inside the closer (e.g. `#{{tag}}x#`) | Drop trailing whitespace after the tag |

**Example:**

```dart
text /*x{{some-key}}*/ more
```

**Template output:**

```dart
text{{some-key}} more
```

Use `clay preview --template-only` to leave Mustache tags intact for inspection, or `clay preview --vars key=value` to render them with Mason.

---

## Spacing groups

**Spacing groups** expand a compact action list into literal newlines and spaces. They are useful for controlling blank lines or indentation in generated templates without embedding fragile whitespace in reference comments.

| Flavor | Syntax |
| --- | --- |
| C-style | `/*w <actions> w*/` |
| Hash | `#w <actions> w#` |
| HTML | `<!--w <actions> w-->` |

### Actions

| Action | Meaning | Example |
| --- | --- | --- |
| `Nv` | `N` newline characters | `2v` → two newlines |
| `N>` | `N` space characters | `4>` → four spaces |

Actions are space-separated. An empty action list (`/*w w*/`) removes the marker and any adjacent whitespace on the marker itself.

**Reference:**

```dart
text
/*w 2v 4> w*/
more text
```

**Template output:**

```dart
text

    more text
```

---

## Partials

**Partials** extract a reusable fragment into a separate Mason partial file. The reference block is replaced with a partial include; the extracted content is written to `{{~ <name>.partial }}` in the target directory.

| Marker | Role |
| --- | --- |
| `partial v <name>` | Opens the block and names the partial |
| `partial ^ <name>` | Closes the block; name must match the opening marker |

| Flavor | Open | Close |
| --- | --- | --- |
| C-style | `/*partial v header*/` | `/*partial ^ header*/` |
| Hash | `#partial v header#` | `#partial ^ header#` |
| HTML | `<!--partial v header-->` | `<!--partial ^ header-->` |

**Reference:**

```dart
before
/*partial v header*/line one
line two
/*partial ^ header*/
after
```

**Template output (main file):**

```dart
before
{{> header.partial }}
after
```

**Generated partial file** (`{{~ header.partial }}`):

```
line one
line two
```

Partial names must be non-empty, must not be `.` or `..`, must not contain path separators, and must not include filename-invalid characters (`<>:"|?*` or newlines). `clay validate` reports name mismatches and unmatched `partial v` / `partial ^` pairs.

---

## Validation

Run `clay validate` from the project root (or any subdirectory — Clay discovers the nearest `clay.yaml`) to scan the reference tree for structural annotation issues.

Issues are printed to stderr in `filePath:line:column: message` format. The command exits with code `1` when any issue exists.

### Checked rules

| Area | What is validated |
| --- | --- |
| Remove blocks | Paired `remove-start` / `remove-end` per comment flavor |
| Insert blocks | Paired `insert-start` / `insert-end` per comment flavor |
| Replace blocks | `replace-start` → `with` → `replace-end` sequence; no nesting |
| Partials | Paired `partial v` / `partial ^` with matching names |

Drop markers, Mustache unwrapping, and spacing groups are not structurally validated — they are single-token or self-contained transforms.

### Common messages

| Message | Likely cause |
| --- | --- |
| `Unmatched remove-start marker` | Missing `remove-end` (or mismatched flavor) |
| `Unmatched remove-end marker` | Stray `remove-end` without a start |
| `Nested replace-start is not supported` | Replace block inside another replace block |
| `replace-end without a matching with marker` | `with` section omitted or out of order |
| `partial ^ name "X" does not match partial v name "Y"` | Opening and closing partial names differ |

Validation does not execute transforms — it only checks marker structure. Use `clay preview` to verify the generated content looks correct.

---

## Quick reference

| Marker | Purpose |
| --- | --- |
| `drop` | Remove from marker to end of file |
| `remove-start` / `remove-end` | Remove a content block |
| `replace-start` / `with` / `replace-end` | Replace a block with template lines |
| `insert-start` / `insert-end` | Insert template lines at a position |
| `{{…}}` in comments | Unwrap Mustache tags for Mason |
| `w <actions> w` | Expand newlines (`Nv`) and spaces (`N>`) |
| `partial v <name>` / `partial ^ <name>` | Extract a Mason partial |

See also [`clay.yaml`](../README.md#clayyaml) for config-driven transforms (`replacements`, `lineDeletions`, `ignore`), the [JSON schema](clay.schema.json) for editor validation, and the [README annotation overview](../README.md#annotation-overview).
