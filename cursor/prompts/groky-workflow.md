# Groky — Grok 4.7 High + Composer 2.5 Execution Prompt

Use the active Groky Cursor hierarchy for this task.

## Task

[State exactly what you want accomplished.]

## Context

[Provide only the information needed to start. Let the Grok High parent inspect the repository for the rest.]

## Model policy

Fast mode is always off. Do not enable Fast for any managed model or subagent.

- Grok High parent: `grok-4.7-high`, launcher-enforced.
- Composer implementer: `composer-2.5[fast=false]`.
- Grok High reviewer: `grok-4.7-high`, fresh-context only.
- Grok xHigh escalation: `grok-4.7-xhigh`.

Prefer direct parent tools or the pinned custom agents over unspecified/built-in subagents whose speed variant cannot be verified. Do not invoke `grok-advisor` or `grok-architect`; those roles are folded into the parent.

## Execution policy

Grok 4.7 High owns the task. Inspect relevant code, define lightweight acceptance criteria, and either implement a small local change or delegate bulk/mechanical/multi-file work to `composer-owner`. Run deterministic validation, inspect the final diff, fix issues, and finish without calling `grok-reviewer` merely to satisfy process.

Use `grok-reviewer` after deterministic validation only for important or high-risk changes where a fresh-context High pass materially improves confidence. Give it a compact handoff containing objective, acceptance criteria, relevant architecture, changed files, important decisions, checks already run, known uncertainty, and the git diff.

Use `grok-escalation` only if substantial uncertainty remains after credible Grok High parent attempts. Grok xHigh advises; the parent routes; Composer implements bulk work.

Prefer deterministic tests/checks over additional model-review passes. Use relevant unit tests, integration tests, type checks, lint, builds, runtime/browser checks, or focused reproductions. Do not run irrelevant expensive suites merely to satisfy a checklist.

Keep changes minimal and coherent. Avoid unrelated cleanup. Preserve existing APIs and behavior unless the task requires changing them.

## Completion requirements

Do not claim completion until:

- requested behavior exists;
- relevant deterministic validation has run;
- the final diff has been inspected;
- valid reviewer or escalation findings are handled when those agents were warranted;
- remaining risks or limitations are documented.

For routine work, the Grok High parent may complete without `grok-reviewer`.

## Final response

Report concisely:

1. What changed.
2. What was validated and the result.
3. Any meaningful remaining limitation or risk.
