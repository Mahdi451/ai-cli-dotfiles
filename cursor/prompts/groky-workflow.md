# Groky — Composer 2.5 + Grok 4.6 Execution Prompt

Use the active Groky Cursor hierarchy for this task.

## Task

[State exactly what you want accomplished.]

## Context

[Provide only the information needed to start. Let Composer inspect the repository for the rest.]

## Model policy

Fast mode is always off. Do not enable Fast for any managed model or subagent.

- Composer parent: `fast=false`, launcher-enforced.
- Composer delegated role: `composer-2.5[fast=false]`.
- Grok Medium advisor: `grok-4.6[effort=medium,fast=false]`.
- Grok High architect/reviewer: `grok-4.6[effort=high,fast=false]`.
- Grok xHigh escalation: `grok-4.6[effort=xhigh,fast=false]`.

Prefer direct parent tools or the pinned custom agents over unspecified/built-in subagents whose speed variant cannot be verified.

## Execution policy

Composer 2.5 owns the task. For routine work, inspect relevant code, define lightweight acceptance criteria, implement, run deterministic validation, inspect the final diff, fix issues, and finish without calling Grok merely to satisfy process.

Use `grok-advisor` only after a credible Composer attempt when targeted reasoning/debugging is likely to save time.

Use `grok-architect` before implementation only when the task materially changes architecture, security boundaries, persistence/migrations, concurrency/synchronization, public APIs/interfaces, or similarly consequential cross-cutting design.

Use `grok-reviewer` after deterministic validation only for important or high-risk changes where independent review materially improves confidence. Give it a compact handoff containing objective, acceptance criteria, relevant architecture, changed files, important decisions, checks already run, known uncertainty, and the git diff.

Use `grok-escalation` only if substantial uncertainty remains after credible Composer and Grok High attempts. Grok advises; Composer implements.

Prefer deterministic tests/checks over additional model-review passes. Use relevant unit tests, integration tests, type checks, lint, builds, runtime/browser checks, or focused reproductions. Do not run irrelevant expensive suites merely to satisfy a checklist.

Keep changes minimal and coherent. Avoid unrelated cleanup. Preserve existing APIs and behavior unless the task requires changing them.

## Completion requirements

Do not claim completion until:

- requested behavior exists;
- relevant deterministic validation has run;
- the final diff has been inspected;
- valid Grok findings are handled when Grok review was warranted;
- remaining risks or limitations are documented.

For routine work, Composer may complete without Grok review.

## Final response

Report concisely:

1. What changed.
2. What was validated and the result.
3. Any meaningful remaining limitation or risk.
