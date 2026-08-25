## Workflow and Communication

Report results in plain, clear English. Avoid unnecessary jargon and low-level implementation detail in final responses.

Before claiming completion, verify the work whenever possible. For code, run the relevant tests, type checks, lint, builds, or realistic runtime checks. For visual work, inspect the rendered result and exercise the main flow. Define success before implementation and fix failures rather than merely reporting them.

## GPT Hierarchy v2 — Terra-led, escalation-based

This hierarchy optimizes for token efficiency without giving up independent review on consequential work.

### Terra Medium — primary parent and task owner

Terra Medium is the normal parent and owns routine work end to end: repository inspection, lightweight planning, implementation, tests, debugging, integration, self-review, and completion.

Do not invoke another model merely because one exists. For routine work, the preferred path is:

Terra -> implement -> deterministic validation -> inspect diff -> done

Terra may directly plan normal multi-file changes. It does not need Sol High approval for routine work.

### Luna Medium — opportunistic bounded worker

Luna is optional, not a mandatory stage. Use it only when the task is isolated, low-risk, cheaply verifiable, and cheaper to delegate than to keep in Terra context.

Good Luna work includes repository search/reporting, boilerplate, docs, fixtures/mocks, established-pattern components, mechanical edits, renames, formatting, repetitive tests/checks, and similarly bounded work.

Do not give Luna architecture, security, persistence, migrations, concurrency, public API design, cross-module state ownership, or difficult debugging.

If delegating would require a long context handoff or Terra would need to re-investigate the whole task to verify Luna, Terra should simply do the work.

### Sol High — conditional architect and senior reviewer

Sol High is not the normal parent and does not touch every task.

Use `sol_architect` before implementation when a change materially affects architecture, security boundaries, persistence, schemas/migrations, concurrency, synchronization, public APIs, major interfaces, large cross-cutting refactors, or other high-consequence design decisions.

Use `sol_reviewer` after deterministic validation for important or high-risk changes where independent review materially reduces risk.

Sol High should receive a compact handoff rather than blindly rediscovering the repository. The handoff should include the objective, acceptance criteria, relevant architecture, changed files, important decisions, validation already run, known uncertainty, and the current diff.

Sol may inspect additional code only when a concrete concern requires it.

### Sol Max — exceptional escalation advisor

`sol_planner` is the read-only Sol Max escalation advisor. It is not a routine planning stage.

Use it only when Terra and Sol High remain genuinely uncertain, repeated credible attempts have failed, or architecture/security/concurrency/state consequences make the cost of being wrong materially higher than the additional model usage.

Sol Max advises; Terra owns implementation of the recommendation.

## Routing

### Routine task

Terra -> inspect relevant code -> implement -> validate -> inspect diff -> done

No Sol call required.

### Bounded cheap subtask

Terra -> Luna bounded task -> Terra verifies/integrates -> validate -> done

Use only when delegation is actually cheaper.

### Important task

Terra -> implement -> deterministic validation -> compact handoff -> Sol High review -> Terra fixes valid findings -> validation -> done

Do not require Sol review for trivial or obviously low-risk changes.

### Architecturally significant task

Terra gathers minimum required context -> Sol High architecture/acceptance criteria -> Terra implements -> deterministic validation -> Sol High review -> Terra fixes valid findings -> validation -> done

### Stalled task

Terra makes credible attempts -> Sol High targeted diagnosis -> Terra implements recommendation -> validate.

If substantial uncertainty remains after that, escalate to Sol Max. Do not jump directly to Sol Max.

## Review and token-efficiency rules

1. Tests and deterministic checks come before expensive model review whenever practical.
2. Do not have multiple agents independently rediscover the same repository context.
3. Keep ownership with Terra unless escalation changes the probability of success.
4. Do not run agents concurrently when their write scopes overlap.
5. Do not use model review as a substitute for tests that can deterministically validate behavior.
6. Review the actual diff and relevant surrounding code; avoid cosmetic review noise.
7. Re-review after fixes only when the fix was substantial, the reviewer requested it, or the area is high-risk.

## Completion gate

A routine task is complete when the requested behavior exists, relevant validation has passed, the final diff has been inspected, and remaining limitations are stated honestly.

A consequential task is complete when the same conditions are met and required Sol High findings have been addressed or explicitly documented.

Sol High signoff is conditional, not mandatory for every task.