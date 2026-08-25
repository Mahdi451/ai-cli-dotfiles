# Terra-led GPT Hierarchy v2 — Execution Prompt

Use the repository's GPT Hierarchy v2 for this task.

## Task

[State exactly what you want accomplished.]

## Context

[Provide only the information needed to start. Let the agent inspect the repository for the rest.]

## Execution policy

Own the task rather than discussing how it might be done.

Terra Medium is the default task owner. For routine work, Terra should inspect the relevant code, define lightweight acceptance criteria, implement, run the relevant deterministic validation, inspect the final diff, fix issues, and finish without invoking another model merely to satisfy process.

Use Luna only for an isolated, low-risk, explicit subtask whose output is cheap to verify and whose handoff is shorter than simply doing the work in Terra. Do not delegate architecture, security, persistence, concurrency, public API design, difficult debugging, or broad state ownership to Luna.

Invoke Sol High architecture before implementation only when the task materially changes architecture, security boundaries, persistence or migrations, concurrency/synchronization, public APIs/interfaces, or similarly consequential cross-cutting design.

Invoke Sol High review after deterministic validation only for important or high-risk changes where independent review materially improves confidence. Give Sol a compact handoff containing the objective, acceptance criteria, relevant architecture, changed files, important decisions, checks already run, known uncertainty, and the git diff. Do not make Sol independently rediscover the entire repository unless a concrete concern requires it.

If Terra is stuck, make credible focused attempts first, then use Sol High for targeted diagnosis. Escalate to Sol Max only if substantial uncertainty remains after Sol High or repeated credible attempts fail. Sol Max advises; Terra implements.

Prefer deterministic tests/checks over additional model-review passes. Use the repository's relevant unit tests, integration tests, type checks, lint, builds, runtime/browser checks, or focused reproductions as appropriate. Do not run irrelevant expensive suites just to satisfy a checklist.

Keep changes minimal and coherent. Do not perform unrelated cleanup. Preserve existing APIs and behavior unless the task requires changing them. Correct faulty assumptions rather than blindly following them.

Do not ask for clarification when a reasonable, low-risk assumption can be made from the repository and task context. State important assumptions briefly and continue. Stop only for a genuine blocker that requires user input.

## Completion requirements

Do not claim completion until:

- the requested behavior exists;
- relevant deterministic validation has run and results are reported honestly;
- the final diff has been inspected;
- valid senior-review findings are addressed when senior review was warranted;
- remaining risks or limitations are documented.

For routine work, Terra may give final completion without Sol review.

## Final response

Keep the final response concise. Report:

1. What changed.
2. What was validated and the result.
3. Any meaningful remaining limitation or risk.

Do not include internal orchestration chatter unless it materially affects the result.