# AI CLI dotfiles

Portable Linux/WSL configuration for the official Cursor and Codex CLIs. The repository installs reviewed instructions, agent roles, guarded launchers, selected preferences, and shell aliases. It does not install either CLI, sign you in, or place credentials, sessions, history, caches, or machine-local trust state in Git.

## Model workflows

The repository intentionally supports separate Cursor and Codex hierarchies.

### Cursor — Sol/Terra/Luna

```bash
cagent    # cursor-st, normal approval behavior
cursory   # cursor-st --yolo
```

Sol High is the parent, Terra is the primary implementer, Luna is bounded support, and Sol Max is escalation.

All managed Cursor models are explicitly non-Fast:

| Role | Model |
| --- | --- |
| Sol High parent | `gpt-5.6-sol` + high reasoning + `fast=false` |
| Sol Max | `gpt-5.6-sol-max[fast=false]` |
| Terra implementer | `gpt-5.6-terra-medium[fast=false]` |
| Terra reviewer | `gpt-5.6-terra-high[fast=false]` |
| Luna worker | `gpt-5.6-luna-medium[fast=false]` |

`cursor-st` rewrites only the selected parent model fields to the intended non-Fast values immediately before launch and rejects caller `--model` overrides.

### Cursor — Composer 2.5 + Grok 4.6 (Groky)

```text
Routine:
  Composer -> implement -> deterministic validation -> diff inspection -> done

Stalled:
  Composer -> Grok Medium advisor -> Composer -> validate

Important:
  Composer -> validate -> Grok High reviewer -> Composer fixes -> validate -> done

Architectural:
  Grok High architect -> Composer -> validate -> Grok High reviewer -> done

Exceptional:
  Composer/Grok High remain uncertain -> Grok xHigh advisor -> Composer -> validate
```

Use:

```bash
groky-safe   # cursor-st --groky, normal Cursor approvals
groky        # cursor-st --groky --yolo, full-autonomy behavior
```

Fast is always off:

| Role | Model |
| --- | --- |
| Composer parent | `composer-2.5` + `fast=false` |
| Composer delegate | `composer-2.5[fast=false]` |
| Grok advisor | `grok-4.6[effort=medium,fast=false]` |
| Grok architect | `grok-4.6[effort=high,fast=false]` |
| Grok reviewer | `grok-4.6[effort=high,fast=false]` |
| Grok escalation | `grok-4.6[effort=xhigh,fast=false]` |

`cursor-st --groky` forces the selected Composer parent to non-Fast immediately before startup. Custom agents carry independent `fast=false` pins. The launcher doctor rejects managed custom agents that are missing the explicit pin. Prefer direct parent tools or pinned custom agents over built-in/automatic subagents whose speed variant cannot be verified.

The Groky routing rule is installed as a dormant template (`alwaysApply: false`). `cursor-st --groky` renders an active project-local copy and swaps project-specific Sol/Terra/Luna links for Composer/Grok links. Normal `cursor-st` reverses that swap, keeping both Cursor hierarchies isolated.

See `cursor/GROKY.md` and `cursor/prompts/groky-workflow.md`.

### Codex — GPT Hierarchy v2

The home Codex hierarchy is Terra-led and escalation-based:

```text
Routine:       Terra -> validate -> done
Bounded:       Terra -> Luna -> Terra verify -> validate -> done
Important:     Terra -> validate -> Sol High review -> Terra fix -> done
Architectural: Sol High architect -> Terra -> validate -> Sol High review -> done
Exceptional:   Terra -> Sol High -> Sol Max only if still materially uncertain
```

| Role | Model + effort | Responsibility |
| --- | --- | --- |
| Terra parent | `gpt-5.6-terra` + medium | Default task owner |
| Luna worker | `gpt-5.6-luna` + medium | Optional bounded low-risk support |
| Terra reviewer | `gpt-5.6-terra` + high | Optional routine second pass |
| Sol architect | `gpt-5.6-sol` + high | Conditional architecture/acceptance criteria |
| Sol reviewer | `gpt-5.6-sol` + high | Conditional independent senior review |
| Sol Max advisor | `gpt-5.6-sol` + max | Exceptional escalation |

The primary full-approval alias for this home GPT hierarchy is:

```bash
cyolo   # codex-st --dangerously-bypass-approvals-and-sandbox
```

`codexy` is retained only as a backward-compatible alias for the same command. Cursor's `fast` toggle is not part of the Codex model configuration.

See `codex/HIERARCHY.md` and `codex/prompts/terra-led-workflow.md`.

## Prerequisites

Use Linux or WSL with Bash, Python 3.11+, Git, and `rg`. Install and sign in to the official Cursor CLI (`agent` or `cursor-agent`) and/or official `codex` executable separately.

```bash
git clone git@github.com:YOUR-ACCOUNT/ai-cli-dotfiles.git
cd ai-cli-dotfiles
```

## Validate before installation

```bash
./doctor.sh --repo-only
./tests/smoke-test.sh
git diff --check
```

## Install

```bash
./install.sh --dry-run
./install.sh
source ~/.bashrc
./doctor.sh
```

The installer creates backups before changes, merges selected Cursor hooks/preferences rather than replacing them wholesale, and preserves an existing Codex `~/.codex/config.toml` unless `--replace-config` is explicitly used.

Useful options:

| Option | Effect |
| --- | --- |
| `--copy` | Install independent copies instead of symlinks |
| `--cursor-only` | Install Cursor assets and shared aliases only |
| `--codex-only` | Install Codex assets and shared aliases only |
| `--replace-config` | Back up and replace the Codex base config template |
| `--force` | Replace a protected changed/unrecognized target after backup |
| `--full-access` | Store Cursor unrestricted approval/disabled sandbox preferences |

## Everyday commands

```bash
cd ~/projects/example-app

# Existing Cursor hierarchy
cagent "Inspect this project and propose a plan."
cursory "Implement the reviewed change and validate it."

# Composer + Grok Cursor hierarchy
groky-safe "Implement the requested change and validate it."
groky "Implement the reviewed change and validate it."

# Home GPT/Codex hierarchy
codex-st "Implement the requested change and validate it."
cyolo "Implement the reviewed change and validate it."
```

| Command | Behavior |
| --- | --- |
| `cagent` | Managed Sol-led Cursor workflow, normal approvals |
| `cursory` | Same Sol-led Cursor workflow with Cursor `--yolo` |
| `groky-safe` | Composer 2.5 + Grok 4.6 hierarchy, normal approvals |
| `groky` | Same Composer + Grok hierarchy with Cursor `--yolo` |
| `codex-st` | Managed Terra-led GPT Hierarchy v2 with normal Codex approvals/sandbox |
| `cyolo` | Primary GPT Hierarchy v2 alias with `--dangerously-bypass-approvals-and-sandbox` |
| `codexy` | Backward-compatible alias for `cyolo` |
| `cdx` | Raw official `codex` command |

High-risk launchers change execution permissions, not model quality. Use `cursory`, `groky`, and `cyolo` only in trusted or appropriately sandboxed environments.

## Inspect configured flows

```bash
cursor-st --show-flow
cursor-st --doctor
cursor-st --groky --show-flow
cursor-st --groky --doctor
codex-st --show-flow
codex-st --doctor
cdoctor
```

## Installed mappings

| Repository source | Destination |
| --- | --- |
| `cursor/agents/*.md` | `~/.cursor/agents/` |
| `cursor/rules/*.mdc` | `~/.cursor/rules/` |
| `cursor/hooks.json` | merged into `~/.cursor/hooks.json` |
| `cursor/cli-config.json` | selected portable fields merged into `~/.cursor/cli-config.json` |
| `bin/cursor-st` | `~/.local/bin/cursor-st` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `codex/rules/default.rules` | `~/.codex/rules/default.rules` |
| `codex/config/sol-terra-luna.config.toml` | `~/.codex/sol-terra-luna.config.toml` |
| `codex/agents/*.toml` | `~/.codex/agents/` |
| `codex/config/config.toml` | `~/.codex/config.toml` only if missing or explicitly replaced |
| `bin/codex-st` | `~/.local/bin/codex-st` |
| `shell/ai-cli-aliases.sh` | `${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles/ai-cli-aliases.sh` |

`CURSOR_HOME`, `CODEX_HOME`, `XDG_STATE_HOME`, and `XDG_CONFIG_HOME` are honored where applicable.

## Maintenance

```bash
./doctor.sh --repo-only
./tests/smoke-test.sh
git diff --check
./uninstall.sh --dry-run
./uninstall.sh --restore
```

To capture reviewed portable state:

```bash
./backup-current.sh
./backup-current.sh --include-codex
```

The backup workflow preserves the selected-model `fast=false` parameter rather than stripping it.

## Security

Never commit credentials, authentication JSON, private keys, `.env` files, sessions, logs, model history, local databases, machine trust entries, or other secrets. The scanner is a guardrail, not permission to commit sensitive material.

Repository validation proves internal consistency of the portable files; it does not prove account access, model availability, or that unrestricted execution is safe in a particular project.
