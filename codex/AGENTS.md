## Workflow and Communication

When you report results back to me, explain what you did and what happened in plain, clear English. Avoid jargon, low-level implementation details, and code-speak in your final responses. Write as if you’re explaining to a smart person who isn’t looking at the code.

Before you tell me you’re done, verify your own work whenever possible. If you write code, try to run it using the tools available in this environment. Check the output and confirm it does what was asked.

If you build something visual (for example, a web page or UI), try to view it, click through the main flows, and make sure things render and behave correctly. If you write a script, run it against realistic input and inspect the results. If there are edge cases you can simulate, try them.

Define “done” for yourself before you start each task: what does success look like? Use that as a checklist before you report back. If something fails or looks wrong, fix it and re-test instead of just flagging it. Only tell me you’re finished when you’ve either confirmed it works or you’ve hit a genuine blocker that requires my input.

## Model Routing Workflow

Sol High is the normal parent and lead. It performs repository inspection,
planning, acceptance criteria, complete-diff review, and final signoff. It may
directly handle hard implementation when appropriate.

Terra Medium is the default primary implementer for roughly 70–80% of ordinary
implementation, tests, routine debugging, APIs, components, CLIs, backend
logic, and integration. This is a routing target, not a quota.

Luna Medium is limited to explicit bounded low-risk repository search,
boilerplate, docs, fixtures/mocks/schemas, established-pattern basic
components, mechanical changes, repetitive tests/checks, formatting, and
reporting. Luna is never the final reviewer.

### Canonical workflow

1. Sol High inspects the repository, plans, and sets acceptance criteria.
2. Terra performs core implementation and tests.
3. Luna provides only explicit bounded support.
4. Terra integrates and performs routine/advisory review, especially for Luna work.
5. Sol High reviews the complete integrated diff and alone gives final signoff.

Do not run agents concurrently when their write scopes overlap.

### Sol Max escalation advisor

`sol_planner` is a read-only Sol Max escalation advisor, not a mandatory stage.
Invoke it only for architecture or security risk, unusually difficult
reasoning, stalled debugging, or a fundamental review finding. It may return
`[SOL]`, `[TERRA]`, and `[LUNA]` ownership guidance to the Sol High parent.

Do not use Sol Max for routine coding, test execution, formatting,
documentation, simple debugging, or ordinary review.

### Completion gate

Do not claim completion until:

- Required implementation exists.
- Relevant verification has run.
- Test results are reported honestly.
- Terra routine-review findings are addressed or explicitly documented.
- Sol High has reviewed the complete integrated diff and given final signoff.
- Remaining limitations are explicitly documented.
