# Cursor Groky hierarchy

Groky is the token-conscious Cursor CLI workflow built around Composer 2.5 as the parent and Grok 4.6 as conditional senior reasoning/review. It is implemented as a mode of the existing guarded `cursor-st` launcher rather than as a second executable.

## Commands

```bash
groky-safe "implement the requested change"
groky "implement the reviewed change and validate it"
```

- `groky-safe` expands to `cursor-st --groky` and uses normal Cursor approval behavior.
- `groky` expands to `cursor-st --groky --yolo` and uses the same hierarchy with full-autonomy behavior.

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

## Model pins

Custom Grok subagents use explicit non-Fast model parameters:

```text
grok-advisor     grok-4.6[effort=medium,fast=false]
grok-architect   grok-4.6[effort=high,fast=false]
grok-reviewer    grok-4.6[effort=high,fast=false]
grok-escalation  grok-4.6[effort=xhigh,fast=false]
```

The parent launcher uses the official `composer-2.5` CLI model ID by default. Cursor's handling of standard versus Fast parent sessions has varied across CLI builds, so verify the effective tier on the target work machine:

```bash
cursor-st --groky --doctor
agent models
```

If a particular Cursor CLI build exposes a distinct verified non-Fast parent ID, set it without editing the repository:

```bash
export CURSOR_GROKY_PARENT_MODEL='<verified-local-composer-2.5-standard-id>'
```

Do not guess model slugs.

## Workflow isolation

The repository installs `groky-routing-template.mdc` as a dormant user rule with `alwaysApply: false`. When `cursor-st --groky` starts inside a project, it renders a managed project-local copy with `alwaysApply: true`, links the four Grok agents, and removes matching Sol/Terra/Luna project links. Those generated project files are excluded through `.git/info/exclude`.

When normal `cursor-st` starts again, it removes the matching Groky project files before restoring the Sol/Terra/Luna project links. The user-level Grok agent definitions remain installed, but their descriptions and both routing rules explicitly restrict them to Groky sessions.

`cursor-st --clean-project` removes matching managed files for both Cursor hierarchies.
