# Composer + Grok Groky Workflow — Execution Prompt

Use the active Groky hierarchy for this task.

## Task

[State exactly what you want accomplished.]

## Context

[Provide only the information needed to start. Let Composer inspect the repository for the rest.]

## Execution policy

Own the task rather than discussing how it might be done.

Composer 2.5 is the default task owner. For routine work, Composer should inspect only the relevant code, define lightweight acceptance criteria when useful, implement, run relevant deterministic validation, inspect the final diff, fix issues, and finish without invoking another model merely to satisfy process.

Use `grok-advisor` only after a credible Composer attempt when targeted difficult reasoning or debugging is likely to save time.

Use `grok-architect` before implementation only when the task materially changes architecture, security boundaries, persistence or migrations, concurrency/synchronization, public APIs/interfaces, or similarly consequential cross-cutting design.

Use `grok-reviewer` after deterministic validation only for important or high-risk changes where independent review materially improves confidence.

Use `grok-escalation` only when credible Composer and Grok High attempts still leave material uncertainty. It advises; Composer implements.

Before a Grok call, provide a compact handoff containing the objective, acceptance criteria, relevant architecture, relevant or changed files, important decisions, checks already run, observed failure/uncertainty, and the current git diff when reviewing implementation. Do not make Grok rediscover the whole repository unless a concrete concern requires it.

Prefer deterministic tests/checks over additional model-review passes. Use the repository's relevant unit tests, integration tests, type checks, lint, builds, runtime/browser checks, or focused reproductions as appropriate. Do not run irrelevant expensive suites just to satisfy a checklist.

Do not use Sol/Terra/Luna agents in this Groky task. Avoid unspecified/built-in subagents when a custom Grok role above is the intended escalation. Keep implementation ownership with Composer.

Keep changes minimal and coherent. Avoid unrelated cleanup. Preserve existing APIs and behavior unless the task requires changing them.

## Completion requirements

Do not claim completion until:

- the requested behavior exists;
- relevant deterministic validation has run and results are reported honestly;
- the final diff has been inspected;
- valid Grok findings are addressed when Grok review was warranted;
- remaining risks or limitations are documented.

Routine work may complete with Composer alone after validation.

## Final response

Keep the final response concise. Report:

1. What changed.
2. What was validated and the result.
3. Any meaningful remaining limitation or risk.
