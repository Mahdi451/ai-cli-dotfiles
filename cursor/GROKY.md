# Cursor Groky hierarchy

Groky is the token-conscious Cursor CLI workflow built around Composer 2.5 as the parent and Grok 4.6 as conditional senior reasoning/review. It is implemented as a mode of the existing guarded `cursor-st` launcher rather than as a second executable.

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
  Composer 2.5 -> implement -> deterministic validation -> diff inspection -> done

Stalled:
  Composer -> Grok 4.6 Medium advisor -> Composer -> validate

Important:
  Composer -> validate -> Grok 4.6 High reviewer -> Composer fixes -> validate -> done

Architectural:
  Grok 4.6 High architect -> Composer -> validate -> Grok High reviewer -> done

Exceptional:
  Composer/Grok High remain uncertain -> Grok 4.6 xHigh advisor -> Composer -> validate
```

Grok agents are read-only. Composer owns implementation.

## Fast policy: always off

Fast mode is never part of the managed hierarchy.

```text
Composer parent    composer-2.5 + fast=false
Composer delegate  composer-2.5[fast=false]
grok-advisor       grok-4.6[effort=medium,fast=false]
grok-architect     grok-4.6[effort=high,fast=false]
grok-reviewer      grok-4.6[effort=high,fast=false]
grok-escalation    grok-4.6[effort=xhigh,fast=false]
```

`cursor-st --groky` rewrites Cursor's selected Composer parent configuration to `fast=false` immediately before launch and rejects caller model overrides. It also sets the configured Explore model to an explicit non-Fast Composer selection as a defensive preference. Custom agents are independently pinned with bracket parameters, and `cursor-st --groky --doctor` rejects a managed custom agent that lacks an explicit `fast=false` model pin.

Because Cursor has had known issues around automatic/built-in subagent model variants, those are not part of the Groky hierarchy. Prefer direct parent tools or the pinned custom agents when model speed must be deterministic.

## Workflow isolation

The repository installs `groky-routing-template.mdc` as a dormant user rule with `alwaysApply: false`. When `cursor-st --groky` starts inside a project, it renders a managed project-local copy with `alwaysApply: true`, links the Composer/Grok agents, and removes matching Sol/Terra/Luna project links. Those generated project files are excluded through `.git/info/exclude`.

When normal `cursor-st` starts again, it removes the matching Groky project files before restoring the Sol/Terra/Luna project links. The user-level Grok agent definitions remain installed, but their descriptions and both routing rules explicitly restrict them to Groky sessions.

`cursor-st --clean-project` removes matching managed files for both Cursor hierarchies.

## Verification

```bash
cursor-st --groky --doctor
cursor-st --groky --show-flow
agent models
```

The first two commands verify the managed files and explicit non-Fast pins. `agent models` remains useful for confirming the account exposes Composer 2.5 and Grok 4.6.
