# Opus — Claude Opus 5.5 High + Composer 2.5 Execution Prompt

Use the active Opus Cursor hierarchy for this task.

## Task

[State exactly what you want accomplished.]

## Context

[Provide only the information needed to start. Let the Opus High parent inspect the repository for the rest.]

## Model policy

Fast mode is always off. Do not enable Fast for any managed model or subagent.

- Opus High parent: `claude-opus-5-5-high` (300K context), launcher-enforced.
- Composer implementer: `opus-composer`, `composer-2.5[fast=false]`.
- Opus reviewer: `opus-reviewer`, `claude-opus-5-5-medium`, fresh-context only.
- Opus xHigh escalation: `opus-escalation`, `claude-opus-5-5-xhigh`.

Prefer direct parent tools or the pinned custom agents over unspecified/built-in subagents whose speed variant cannot be verified. Do not invoke Sol/Terra/Luna or Groky agents.

## Execution policy

Opus 5.5 High owns the task. Inspect relevant code, define lightweight acceptance criteria, and implement the change. Delegate to `opus-composer` only when the approach is decided and the work spans three or more files, is repetitive, or is mostly tests/fixtures/boilerplate. Keep security, auth, persistence, concurrency, public API, migration, and unsettled design work in the parent. Run deterministic validation, inspect the final diff, fix issues, and finish without calling `opus-reviewer` merely to satisfy process.

Use `opus-reviewer` after deterministic validation only for Composer-written changes that touch security, auth, persistence, concurrency, public APIs, or migrations. Give it a compact handoff containing objective, acceptance criteria, non-goals, relevant architecture, changed files, important decisions, checks already run, known uncertainty, and the git diff.

Use `opus-escalation` only if substantial uncertainty remains after credible Opus High parent attempts. Opus xHigh advises; the parent routes; Composer implements gated bulk work.

Prefer deterministic tests/checks over additional model-review passes. Use relevant unit tests, integration tests, type checks, lint, builds, runtime/browser checks, or focused reproductions. Do not run irrelevant expensive suites merely to satisfy a checklist.

Keep changes minimal and coherent. Avoid unrelated cleanup. Preserve existing APIs and behavior unless the task requires changing them.

## Completion requirements

Do not claim completion until:

- requested behavior exists;
- relevant deterministic validation has run;
- the final diff has been inspected;
- valid reviewer or escalation findings are handled when those agents were warranted;
- remaining risks or limitations are documented.

For routine work, the Opus High parent may complete without `opus-reviewer`.

## Final response

Report concisely:

1. What changed.
2. What was validated and the result.
3. Any meaningful remaining limitation or risk.
