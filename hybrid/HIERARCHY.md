# Hybrid Cursor + Codex Hierarchy v3

Experimental cross-CLI workflow for using Cursor Pro+ and ChatGPT Plus/Codex as complementary systems instead of maintaining duplicate implementation hierarchies.

> **Core rule:** Cursor builds. Codex judges. Grok handles hard builds. Sol handles hard decisions.

This workflow is intentionally additive. Existing `groky`, `groky-safe`, `cyolo`, `codex-st`, and compatibility launchers remain unchanged while v3 is evaluated.

## Model ownership

| Priority | CLI | Model | Effort | Role |
| --- | --- | --- | --- | --- |
| P0 | Cursor | Composer 2.5 | standard, `fast=false` | Default task owner and builder |
| P1 | Cursor | Grok 4.6 | high, `fast=false` | Hard/long-running builder |
| P1 | Cursor | Grok 4.6 | medium, `fast=false` | Focused debugging/reasoning advisor |
| P2 | Codex | GPT-5.6 Terra | high | Independent integrated-diff reviewer |
| P3 | Codex | GPT-5.6 Sol | high | Architect for consequential design decisions |
| P4 | Codex | GPT-5.6 Sol | max | Exceptional escalation only |
| Utility | Codex | GPT-5.6 Luna | medium | Optional cheap read-only/mechanical support in Codex-only contexts |

## Default routing

```text
Routine:
  Composer 2.5
    -> inspect
    -> implement
    -> deterministic validation
    -> diff inspection
    -> done

Hard implementation:
  Composer makes a credible attempt or task is clearly large/long-running
    -> Grok 4.6 High owns implementation
    -> deterministic validation
    -> diff inspection
    -> done or Codex review when consequential

Important change:
  Composer or Grok builds
    -> deterministic validation
    -> Terra High independent review
    -> original builder fixes valid findings
    -> deterministic validation
    -> done

Architectural/high-risk change:
  Sol High architecture + acceptance criteria
    -> Composer for moderate implementation OR Grok High for difficult implementation
    -> deterministic validation
    -> Terra High independent integrated review
    -> builder fixes findings
    -> validate
    -> done

Exceptional uncertainty:
  credible implementation/debug attempts
    -> Terra High targeted review/diagnosis
    -> Sol High if architectural uncertainty remains
    -> Sol Max only if material uncertainty still remains
```

## Routing admission rules

### Composer 2.5

Composer is the default. Keep work here when the task is bounded, repository patterns are clear, and normal implementation/debugging is likely to succeed without expensive escalation.

Typical work:

- normal features
- straightforward bug fixes
- tests
- scripts/configuration
- small and medium refactors
- routine debugging
- documentation and mechanical edits

### Grok 4.6 High builder

Promote Grok from read-only advisor to implementation owner when one or more are true:

- the change spans many modules
- the task is expected to be long-running
- repository understanding is difficult
- implementation is ambiguous or highly agentic
- debugging has survived a credible Composer attempt
- handing advice back to Composer would cost more context than transferring ownership

Grok High is a writer in this v3 workflow. Do not let Composer and Grok edit overlapping files concurrently unless isolated worktrees are used.

### Terra High reviewer

Terra High is the normal independent reviewer for important integrated diffs. It should be read-only and receive a compact handoff rather than rediscovering the whole repository.

Review for:

- correctness/regressions
- missing edge cases
- unsafe assumptions
- security issues
- concurrency/state bugs
- insufficient validation
- unnecessary complexity

Routine low-risk work with strong deterministic validation does not require model review.

### Sol High architect

Use Sol High before implementation when mistakes in the approach would be expensive to unwind:

- architecture
- security boundaries/authentication
- persistence/schema/migrations
- concurrency/synchronization
- public APIs/interfaces
- backwards compatibility
- major cross-cutting refactors
- infrastructure/state ownership

Sol provides architecture, invariants, acceptance criteria, failure modes, affected areas, and validation strategy. Sol does not become the default implementation model.

### Sol Max

Exceptional only. Do not use merely because a task is important. Use after credible attempts plus Terra/Sol High still leave material uncertainty.

## Parallel execution

Git is the coordination layer. Parallel writers must use isolated branches/worktrees.

```text
                     Sol High (plan when needed)
                               |
                 +-------------+-------------+
                 |                           |
          Composer worktree             Grok worktree
             bounded area               bounded area
                 |                           |
                 +-------------+-------------+
                               |
                       integration worktree
                               |
                    tests / lint / build
                               |
                       Terra High review
                               |
                              done
```

Rules:

1. Never allow two writing agents to edit the same checkout concurrently.
2. Prefer non-overlapping file ownership.
3. Each worker returns a commit plus compact handoff.
4. Integrate before senior review so Terra sees the actual combined diff.
5. Deterministic checks run before expensive review whenever practical.

## Compact handoff contract

Every cross-CLI escalation should contain only:

- objective
- acceptance criteria
- relevant architecture
- changed/relevant files
- important implementation decisions
- validation already run and results
- observed failure or remaining uncertainty
- current diff/commit range when reviewing

Avoid sending full conversational history between CLIs.

## Subscription allocation target

Bias high-volume implementation toward Cursor and reserve Codex for shorter, higher-value reasoning/review.

```text
Cursor: Composer + Grok  -> majority of implementation tokens
Codex: Terra + Sol       -> architecture, independent review, escalation
```

Do not spend Cursor's OpenAI-model allowance on a parallel Sol/Terra/Luna implementation hierarchy when the same functional senior layer is already available through the Codex subscription.

## Experimental command surface

Target interface for the branch:

```bash
hybrid "implement the requested change"   # normal approvals
hyolo  "implement the reviewed change"    # trusted/autonomous mode
```

Direct escape hatches should remain:

```text
groky / groky-safe   -> Cursor-only Composer + Grok workflow
cyolo / codex-st     -> Codex-only GPT hierarchy
cdx                  -> raw Codex
```

The hybrid launcher should remain mostly deterministic. It should create/track worktrees, construct compact handoffs, invoke the selected CLI, run validation hooks, and request review. It should not add another LLM whose only job is deciding which LLM to call.

## Migration plan

1. **Phase 1 — branch only:** document v3 and keep existing launchers unchanged.
2. **Phase 2 — Grok builder:** add a writable pinned `grok-builder` role and tests without changing default Groky behavior.
3. **Phase 3 — hybrid launcher:** add `hybrid` / `hyolo` orchestration and worktree helpers.
4. **Phase 4 — validation:** compare routine, hard, architectural, and stalled tasks against current `groky` and `cyolo` flows.
5. **Phase 5 — promotion:** only after validation, make hybrid the recommended top-level workflow; retain old commands as escape hatches/compatibility aliases.

## Success criteria

Promote v3 only if it demonstrably reduces duplicate model calls and handoff overhead while preserving or improving completion rate, validation quality, and recovery from difficult tasks.
