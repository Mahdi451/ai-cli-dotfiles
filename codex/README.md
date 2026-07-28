# Codex framework

Codex CLI 0.145.0 loads its primary configuration from `~/.codex/config.toml`.
This repository intentionally does not import that file automatically: it can
contain machine-specific trusted-project entries or credentials.

Portable, reviewed content can live in:

- `AGENTS.md` for global instructions
- `rules/` for reusable rule files
- `prompts/` for reusable prompt text
- `config/` for sanitized, opt-in templates only

`install.sh --include-codex` installs `AGENTS.md` and `rules/default.rules`;
it never installs credentials, session history, cache, or login state.

The official `codex` executable remains untouched. `cdx` is a convenience
alias. `codexy` uses Codex's documented
`--dangerously-bypass-approvals-and-sandbox` option and is intentionally
labelled dangerous; it is not a replacement for `--yolo`, which Codex does not
support.

Codex does not expose Cursor-style custom planning/reviewer subagents through
the local CLI configuration inspected here. Reproduce the Sol/Terra flow with
explicit prompts and normal code review rather than claiming equivalent agent
orchestration exists.
