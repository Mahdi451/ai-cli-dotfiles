# Codex framework

Codex CLI loads its primary configuration from `~/.codex/config.toml`.
This repository provides a sanitized template for a fresh install, never
imports a live file, and preserves an existing file unless `--replace-config`
is explicitly supplied.

Portable, reviewed content can live in:

- `AGENTS.md` for global instructions
- `rules/` for reusable rule files
- `prompts/` for reusable prompt text
- `config/` for sanitized, opt-in templates only

`install.sh` installs `AGENTS.md`, `rules/default.rules`, the four portable
agent TOMLs, the sanitized base template, `sol-terra-luna.config.toml`, and
`codex-st`. It never imports credentials, session history, cache, login
state, trust entries, notices, migrations, or other machine-local state.

The official `codex` executable remains untouched. `cdx` and `codex` are raw
Codex. `codex-st` selects the `sol-terra-luna` profile, prevents model/profile/
configuration overrides that could bypass it, and forwards normal arguments
and subcommands. `codexy` is the only all-in-one hierarchy command:
`codex-st --dangerously-bypass-approvals-and-sandbox`. It bypasses all
approvals and sandboxing and is safe only in an externally sandboxed
environment. Codex does not support Cursor's `--yolo`.

The profile sets Sol High (`gpt-5.6-sol` at high reasoning) as the parent and
Terra Medium as the default subagent, with multi-agent support enabled. The
canonical flow is Sol High inspection/planning/acceptance, Terra core
implementation/tests, Luna bounded support, Terra integration/routine review,
then Sol High complete-diff review and final signoff. Sol Max is a read-only
escalation advisor only for architecture/security risk, unusually difficult
reasoning, stalled debugging, or fundamental review findings.
