## 0.0.1

- **FEAT**: `ClayCommandRunner` with global flags — `--config`, `--cwd`, `--verbose`, and `--version` (#20).
- **FEAT**: `clay gen` generates a Mason template tree from the reference project; defaults when `clay` is invoked without a subcommand (#21).
- **FEAT**: `clay validate` checks annotation markers across the reference project (#22).
- **FEAT**: `clay preview` transforms a single reference file to stdout with `--file`, optional `--template-only`, and Mason `--vars` (#25).
- **FEAT**: export a public `clay_cli` library API for programmatic command runners and run helpers (#26).
- **FEAT**: delegate generation, validation, and preview to the `clay` library — thin CLI orchestration layer (#51).
- **FEAT**: discover and load `clay.yaml` from the working directory or parent folders; `--reference` and `--target` override config paths (#55).
