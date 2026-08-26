# Hybrid Cursor + Codex v3

Experimental cross-CLI workflow for using **Cursor Pro+** and **ChatGPT Plus / Codex** as one coordinated coding system instead of maintaining duplicate model hierarchies.

> **Core rule:** Cursor builds. Codex judges. Grok handles hard builds. Sol handles hard decisions.

This README describes the `hybrid-cursor-codex-v3` branch only. It intentionally leaves out older standalone Cursor and Codex hierarchies that are not part of the Hybrid v3 design.

## Status

Hybrid v3 is currently an **experimental branch**.

Implemented in this branch today:

- the v3 hierarchy and routing contract;
- model ownership rules;
- parallel Git worktree design;
- cross-CLI handoff rules;
- editable Mermaid diagrams;
- GitHub-renderable SVG visuals.

Planned next:

- writable `grok-builder` role;
- deterministic hybrid router;
- `hybrid` safe launcher;
- `hyolo` trusted/autonomous launcher;
- worktree orchestration helpers;
- automated handoffs between Cursor CLI and Codex CLI;
- validation against representative routine, difficult, architectural, and stalled tasks.

The target commands described below are therefore the **intended v3 interface**, not yet the production default.

## Architecture at a glance

![Hybrid Cursor + Codex v3 overview](hybrid/assets/hybrid-v3-overview.svg)

The hierarchy assigns each subscription a distinct job instead of paying two systems to perform the same role.

| Priority | CLI | Model | Effort | Role |
| --- | --- | --- | --- | --- |
| P0 | Cursor CLI | **Composer 2.5** | standard, `fast=false` | Default builder |
| P1 | Cursor CLI | **Grok 4.6** | high, `fast=false` | Hard / long-running builder |
| P1 | Cursor CLI | **Grok 4.6** | medium, `fast=false` | Focused debugger / advisor |
| P2 | Codex CLI | **GPT-5.6 Terra** | high | Independent reviewer |
| P3 | Codex CLI | **GPT-5.6 Sol** | high | Architect for consequential changes |
| P4 | Codex CLI | **GPT-5.6 Sol** | max | Exceptional escalation only |

The normal ownership model is deliberately simple:

```text
Composer builds normal work
        ↓
Grok takes hard implementation when warranted
        ↓
Deterministic validation
        ↓
Terra reviews important integrated diffs
        ↓
Sol handles architecture / critical decisions only
```

## Why this hierarchy exists

The previous approach treated Cursor and Codex as separate coding worlds. That creates duplicate roles: one implementation hierarchy inside Cursor and another implementation hierarchy inside Codex.

Hybrid v3 instead treats the subscriptions as complementary layers:

```text
Cursor subscription
    ├── Composer 2.5 → routine/high-volume implementation
    └── Grok 4.6    → difficult/long-running implementation

Codex subscription
    ├── Terra High  → independent review
    └── Sol High    → architecture and critical reasoning
```

This reduces duplicate context, duplicate model calls, and unnecessary handoffs while preserving an independent review layer.

## Routing tree

![Hybrid v3 routing tree](hybrid/assets/routing-tree.svg)

The router should be deterministic. Do not add another LLM whose main purpose is deciding which LLM to call.

### Routine and bounded work

Use **Composer 2.5** by default.

Typical work:

- normal features;
- straightforward bug fixes;
- unit and integration tests;
- scripts and configuration;
- small and medium refactors;
- documentation;
- routine debugging;
- mechanical repository changes.

Flow:

```text
Composer 2.5
  → inspect relevant code
  → implement
  → tests / typecheck / lint / build as appropriate
  → inspect final diff
  → done
```

Do not invoke a senior model merely to satisfy process.

### Hard or long-running implementation

Use **Grok 4.6 High** when implementation itself is the difficult part.

Promote work to Grok when one or more are true:

- the change spans many modules;
- repository understanding is difficult;
- the implementation is ambiguous or highly agentic;
- the task is expected to run for a long time;
- difficult debugging survives a credible Composer attempt;
- transferring implementation ownership is cheaper than repeated advisor handoffs.

In Hybrid v3, Grok High is a **writer**, not merely a read-only advisor.

```text
Composer identifies a hard task or makes a credible attempt
        ↓
Grok 4.6 High takes implementation ownership
        ↓
Deterministic validation
        ↓
Review only if the resulting change warrants it
```

### Important changes

Important integrated changes receive an independent **Terra High** review after deterministic validation.

```text
Composer or Grok builds
        ↓
tests / lint / build / runtime validation
        ↓
Terra High read-only review
        ↓
issue found?
   ├── no  → done
   └── yes → original builder fixes
                 ↓
              validate
```

Terra should review the actual integrated diff rather than independently rediscovering the entire repository.

Review for:

- correctness and regressions;
- missing edge cases;
- unsafe assumptions;
- state consistency problems;
- concurrency bugs;
- security problems;
- inadequate validation;
- needless complexity.

Routine low-risk work with strong deterministic validation does not require a model review.

## Architecture and high-risk path

Use **Sol High before implementation** when a bad design decision would be expensive to unwind.

Typical triggers:

- architecture changes;
- authentication or security boundaries;
- persistence, schemas, or migrations;
- concurrency and synchronization;
- state ownership;
- public APIs or interfaces;
- backwards compatibility;
- infrastructure changes;
- major cross-cutting refactors.

Flow:

```text
Sol High
  → architecture
  → invariants
  → acceptance criteria
  → failure modes
  → validation strategy
        ↓
Composer or Grok implements
        ↓
Deterministic validation
        ↓
Terra High integrated review
        ↓
done
```

Use **Sol Max** only when material uncertainty remains after credible implementation attempts plus Terra/Sol High reasoning. Importance alone is not a reason to invoke Max.

## Parallel mode with Git worktrees

![Parallel mode with Git worktrees](hybrid/assets/parallel-worktrees.svg)

Git is the coordination layer between writing agents.

For sufficiently large tasks:

```text
                     Sol High plan when needed
                              │
                 split into bounded ownership
                    ┌─────────┴─────────┐
                    │                   │
           Composer worktree      Grok worktree
                    │                   │
                 commit              commit
                    └─────────┬─────────┘
                              │
                     integration worktree
                              │
                     tests / lint / build
                              │
                       Terra High review
                              │
                             done
```

### Parallel execution rules

1. Never let two writing agents edit the same checkout concurrently.
2. Prefer non-overlapping file ownership.
3. Each worker uses its own branch and worktree.
4. Each worker returns a commit plus a compact handoff.
5. Merge or cherry-pick into an integration worktree.
6. Run deterministic checks on the combined result.
7. Review the integrated diff, not isolated partial diffs, when system behavior depends on both changes.

Do **not** do this:

```text
Composer ─┐
          ├── both editing ./src/foo.ts in one checkout
Grok ─────┘
```

Do this instead:

```text
../project-composer
../project-grok
../project-integrate
```

## Compact cross-CLI handoff

Do not copy entire conversational histories between Cursor and Codex.

Every escalation should contain only what the receiving model needs:

- objective;
- acceptance criteria;
- relevant architecture;
- changed or relevant files;
- important implementation decisions;
- validation already run and results;
- observed failure or remaining uncertainty;
- current diff or commit range when reviewing.

The receiving model expands repository exploration only when a concrete concern requires it.

## Where Grok Bot fits

![Where Grok Bot fits](hybrid/assets/grok-bot-fit.svg)

Grok Bot sits **above** the local CLI hierarchy as a project steward. It should not become another uncontrolled writer in the coding hot path.

Good uses:

- library and dependency research;
- upstream release monitoring;
- GitHub issue triage;
- backlog grooming;
- implementation briefs;
- recurring project routines;
- research and comparisons;
- issue summarization.

Avoid using Grok Bot for:

- random repository edits;
- duplicate code-review loops;
- overlapping hot-path implementation;
- editing the same files as local CLI workers.

The preferred flow is:

```text
Grok Bot
  → research / monitor / triage
  → TASK or implementation brief
  → local Hybrid v3 CLI hierarchy
  → deterministic validation
  → independent review when warranted
```

## Target command surface

Hybrid v3 is intended to expose two primary entry points:

```bash
hybrid "implement the requested change"
hyolo  "implement the reviewed change"
```

### `hybrid`

Target behavior:

- normal approval and sandbox behavior;
- deterministic routing;
- Composer as default builder;
- Grok High for difficult implementation;
- worktree isolation when parallel writers are useful;
- deterministic validation before model review;
- Terra High review when warranted;
- Sol High architecture only for consequential design work.

### `hyolo`

Same hierarchy and routing logic, but intended for trusted/autonomous execution environments.

High-autonomy execution should only be used where the repository and execution environment are appropriately trusted or sandboxed.

## Branch strategy

![Branch strategy and command map](hybrid/assets/branch-strategy-command-map.svg)

The rollout policy for v3 is conservative:

```text
main
  ↓
hybrid-cursor-codex-v3
  ↓
test representative workloads
  ↓
refine routing / prompts / orchestration
  ↓
merge only when the workflow is proven
```

`main` remains the stable baseline while v3 is evaluated independently.

## Repository layout for v3

The branch-specific design documentation lives under `hybrid/`:

```text
hybrid/
├── HIERARCHY.md
├── VISUALS.md
├── assets/
│   ├── hybrid-v3-overview.svg
│   ├── routing-tree.svg
│   ├── parallel-worktrees.svg
│   ├── grok-bot-fit.svg
│   └── branch-strategy-command-map.svg
└── mermaid/
    ├── hybrid-v3-overview.mmd
    ├── routing-tree.mmd
    ├── parallel-worktrees.mmd
    ├── grok-bot-fit.mmd
    └── branch-strategy-command-map.mmd
```

See:

- [`hybrid/HIERARCHY.md`](hybrid/HIERARCHY.md) for the detailed routing contract;
- [`hybrid/VISUALS.md`](hybrid/VISUALS.md) for all diagrams;
- [`hybrid/mermaid/`](hybrid/mermaid/) for editable diagram sources.

As implementation phases land, the branch will add the corresponding launcher, agent, routing, and worktree helpers without reintroducing duplicate standalone hierarchies into this README.

## Development phases

### Phase 1 — hierarchy and documentation

Current branch state.

- define ownership;
- define routing;
- define cross-CLI handoffs;
- define worktree model;
- add visuals and editable sources.

### Phase 2 — Grok builder

- add writable pinned `grok-builder`;
- retain Composer as the default owner;
- verify `fast=false` invariants;
- add role-level validation.

### Phase 3 — hybrid launcher

- implement `hybrid` and `hyolo`;
- add deterministic routing;
- add worktree creation and cleanup;
- construct compact cross-CLI handoffs;
- integrate validation hooks.

### Phase 4 — validation

Compare v3 against representative workloads:

- routine implementation;
- difficult implementation;
- large parallel feature;
- architectural change;
- security-sensitive change;
- difficult debugging;
- stalled task recovery.

Measure:

- completion rate;
- token/context duplication;
- number of model handoffs;
- deterministic validation quality;
- review findings;
- recovery from failed attempts;
- total interaction overhead.

### Phase 5 — promotion

Promote Hybrid v3 only if it demonstrably reduces duplicate model calls and handoff overhead while preserving or improving correctness, validation quality, and difficult-task recovery.

## Design principles

1. **One owner by default.** Routine tasks stay in one implementation context.
2. **Cursor carries implementation volume.** Composer and Grok do most coding work.
3. **Codex provides independent judgment.** Terra and Sol are used where a second reasoning system materially improves confidence.
4. **Deterministic checks come first.** Tests, lint, typecheck, build, runtime checks, and focused reproductions are preferable to ceremonial model reviews.
5. **Escalation is conditional.** Stronger models are used because the task warrants them, not because they are available.
6. **Git coordinates parallel writers.** Separate branches and worktrees prevent agents from fighting over one filesystem.
7. **Handoffs stay compact.** Transfer the task state, not the conversation history.
8. **Main stays stable.** Validate the hybrid workflow on this branch before replacing the existing baseline.

## Short version

```text
Composer builds normally
        ↓
Grok builds the hard stuff
        ↓
Terra reviews important diffs
        ↓
Sol makes consequential decisions
        ↓
Sol Max is the final escalation only
```

That is Hybrid Cursor + Codex v3.