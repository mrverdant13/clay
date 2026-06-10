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
