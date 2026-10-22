# Cursor Groky hierarchy

Groky is the Grok-led Cursor CLI workflow: Grok 4.7 High is the parent, and Composer 2.5 is the implementer. Independent High review and xHigh escalation remain conditional. It is implemented as a mode of the existing guarded `cursor-st` launcher rather than as a second executable.

## Commands

```bash
groky-safe "implement the requested change"
groky "implement the reviewed change and validate it"
```

- `groky-safe` expands to `cursor-st --groky` and uses normal Cursor approval behavior.
- `groky` expands to `cursor-st --groky --yolo` and uses the same hierarchy with full-autonomy behavior.
- `cagent` / `cursory` are reserved for the original Sol/Terra/Luna Cursor hierarchy.
- `cyolo` is reserved for the home GPT/Codex hierarchy and must not be reused by Cursor.

## Routing

```text
Routine:
  Grok 4.7 High parent -> small local edit or Composer 2.5 bulk implement
    -> deterministic validation -> diff inspection -> done

Important:
  Parent/Composer implement -> validate -> Grok 4.7 High reviewer
    -> parent/Composer fixes -> validate -> done

Architectural:
  Grok High parent plans -> Composer implements -> validate
    -> Grok High reviewer -> done

Exceptional:
  Grok High remains uncertain -> Grok 4.7 xHigh advisor -> Composer/parent -> validate
```

`grok-advisor` and `grok-architect` are retired; those roles are folded into the Grok High parent. `grok-reviewer` and `grok-escalation` are read-only. Composer owns bulk implementation.

## Fast policy: always off

Fast mode is never part of the managed hierarchy.

```text
Grok High parent       grok-4.7-high
Composer implementer   composer-2.5[fast=false]
grok-reviewer          grok-4.7-high
grok-escalation        grok-4.7-xhigh
Explore                composer-2.5[fast=false]
```

`cursor-st --groky` launches the Cursor CLI with `--model grok-4.7-high`. That argv pin is required: without it the CLI defaults to `auto` / Auto Balance. Grok 4.7 is catalogued as discrete effort and speed slugs, so non-Fast High is `grok-4.7-high` rather than a parameterized `grok-4.7[...]` override. The launcher also rewrites `cli-config.json` to `grok-4.7-high`, keeps Explore on non-Fast Composer, and rejects caller `--model`/`-m` overrides. Composer stays on `composer-2.5[fast=false]`. `cursor-st --groky --doctor` rejects a Fast Grok slug or a Composer pin that lacks `fast=false`.

Because Cursor has had known issues around automatic/built-in subagent model variants, those are not part of the Groky hierarchy. Prefer direct parent tools or the pinned custom agents when model speed must be deterministic.

## Workflow isolation

The repository installs `groky-routing-template.mdc` as a dormant user rule with `alwaysApply: false`. When `cursor-st --groky` starts inside a project, it renders a managed project-local copy with `alwaysApply: true`, links the Composer implementer and Grok reviewer/escalation agents, removes retired advisor/architect project links, and removes matching Sol/Terra/Luna project links. Stale generated copies from an older Groky template are replaced. Those generated project files are excluded through `.git/info/exclude`.

When normal `cursor-st` starts again, it removes the matching Groky project files before restoring the Sol/Terra/Luna project links. The user-level Grok agent definitions remain installed, but their descriptions and both routing rules explicitly restrict them to Groky sessions.

`cursor-st --clean-project` removes matching managed files for both Cursor hierarchies.

## Verification

```bash
cursor-st --groky --doctor
cursor-st --groky --show-flow
agent models
```

The first two commands verify the managed files and explicit non-Fast pins. `agent models` remains useful for confirming the account exposes Composer 2.5 and Grok 4.7.
