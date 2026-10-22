# Cursor Opus hierarchy

Opus is the Opus-led Cursor CLI workflow: Claude Opus 5.5 High is the parent, and Composer 2.5 is the gated bulk implementer. Independent Opus review and xHigh escalation remain conditional. It is implemented as a mode of the existing guarded `cursor-st` launcher rather than as a second executable.

## Commands

```bash
opusn "implement the requested change"
opus "implement the reviewed change and validate it"
```

- `opusn` expands to `cursor-st --opus` and uses normal Cursor approval behavior.
- `opus` expands to `cursor-st --opus --yolo` and uses the same hierarchy with full-autonomy behavior.
- `groky` / `groky-safe` are reserved for the Grok 4.7 High + Composer hierarchy (see [`GROKY.md`](GROKY.md)).
- `cagent` / `cursory` are reserved for the original Sol/Terra/Luna Cursor hierarchy.
- `cyolo` is reserved for the home GPT/Codex hierarchy and must not be reused by Cursor.

## Routing

```text
Routine:
  Opus 5.5 High parent implements, or delegates gated bulk work to Composer 2.5
  (approach decided; 3+ files, repetitive, or mostly tests/fixtures)
    -> deterministic validation -> diff inspection -> done

Consequential review:
  Composer-written change touching security, auth, persistence,
  concurrency, public API, or migrations -> validate -> Opus 5.5 Medium reviewer
    -> parent/Composer fixes -> validate -> done

Stalled:
  Opus High remains uncertain -> Opus 5.5 xHigh advisor -> Composer/parent -> validate
```

Security, auth, persistence, concurrency, public API, migration, and unsettled design work stays with the parent. Small parent-written edits do not require `opus-reviewer`. `opus-reviewer` and `opus-escalation` are read-only. Composer owns gated bulk implementation.

## Fast policy: always off

Fast mode is never part of the managed hierarchy.

```text
Opus High parent       claude-opus-5-5-high  (config: claude-opus-5-5, context=300k, effort=high, fast=false)
opus-composer          composer-2.5[fast=false]
opus-reviewer          claude-opus-5-5-medium
opus-escalation        claude-opus-5-5-xhigh
Explore                composer-2.5[fast=false]
```

`cursor-st --opus` launches the Cursor CLI with `--model claude-opus-5-5-high`. That argv pin is required: without it the CLI defaults to `auto` / Auto Balance. Opus 5.5 is catalogued as discrete effort and speed slugs, so non-Fast High is `claude-opus-5-5-high`, not `claude-opus-5-5-high-fast`. The launcher also rewrites `cli-config.json` to `claude-opus-5-5` with `context=300k`, `effort=high`, `fast=false`, keeps Explore on non-Fast Composer through `subagentModels.explore` (the CLI only accepts `default` / `inherit` in `exploreSubagentModel`), and rejects caller `--model`/`-m` overrides. `cursor-st --opus --doctor` rejects a Fast Opus slug or a Composer pin that lacks `fast=false`.

Because Cursor has had known issues around automatic/built-in subagent model variants, those are not part of the Opus hierarchy. Prefer direct parent tools or the pinned custom agents when model speed must be deterministic.

## Workflow isolation

The repository installs `opus-routing-template.mdc` as a dormant user rule with `alwaysApply: false`. When `cursor-st --opus` starts inside a project, it renders a managed project-local copy with `alwaysApply: true`, links the Opus Composer, reviewer, and escalation agents, and removes the matching Sol/Terra/Luna and Groky project agents and rendered rules. Those generated project files are excluded through `.git/info/exclude`.

When normal `cursor-st` or `cursor-st --groky` starts again, it removes the matching Opus project files before setting up its own agents and rendered routing rule. The user-level Opus agent definitions remain installed, but their descriptions and the routing rules explicitly restrict them to Opus sessions.

`cursor-st --clean-project` removes matching managed files for all three Cursor hierarchies.

## Verification

```bash
cursor-st --opus --doctor
cursor-st --opus --show-flow
agent models
```

The first two commands verify the managed files and explicit non-Fast pins. `agent models` remains useful for confirming the account exposes Composer 2.5 and Claude Opus 5.5.
