/** Full Mustache tag, including `{{` / `}}` delimiters (e.g. `{{#use_foo}}`, `{{{name}}}`). */
export const MUSTACHE_TAG_PATTERN = String.raw`\{\{\{?[^}]+?\}\}?\}`;

/** Same as [MUSTACHE_TAG_PATTERN] with a capture group for the tag body. */
export const MUSTACHE_TAG_BODY_REGEX = new RegExp(
  MUSTACHE_TAG_PATTERN.replace('[^}]+?', '([^}]+?)'),
  'g',
);
