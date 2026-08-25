# AI CLI dotfiles

Portable Linux/WSL configuration for the official Cursor and Codex CLIs. The repository installs reviewed instructions, agent roles, guarded launchers, selected preferences, and shell aliases. It does not install either CLI, sign you in, or place credentials, sessions, history, caches, or machine-local trust state in Git.

## Model workflows

The repository intentionally supports separate Cursor and Codex hierarchies.

### Cursor — existing Sol/Terra/Luna workflow

The original managed Cursor workflow remains available:

```bash
cagent   # cursor-st, normal approval behavior
cyolo    # cursor-st --yolo
```

This keeps Sol High as the parent, Terra as the primary implementer, Luna as bounded support, and Sol Max as escalation.

### Cursor — Composer 2.5 + Grok 4.6 (Groky)

The token-conscious work hierarchy uses Composer 2.5 as the parent and Grok 4.6 only where stronger reasoning materially improves reliability:

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

The custom Grok agents are pinned to explicit non-Fast variants:

| Role | Model |
| --- | --- |
| Grok advisor | `grok-4.6[effort=medium,fast=false]` |
| Grok architect | `grok-4.6[effort=high,fast=false]` |
| Grok reviewer | `grok-4.6[effort=high,fast=false]` |
| Grok escalation | `grok-4.6[effort=xhigh,fast=false]` |

The parent launcher requests the official `composer-2.5` CLI model ID. Cursor's parent standard/Fast handling has varied across CLI builds, so verify the effective tier on the target machine with `cursor-st --groky --doctor` and `agent models`. If the installed CLI exposes a distinct verified non-Fast Composer parent ID, set `CURSOR_GROKY_PARENT_MODEL` to that exact ID rather than guessing.

The Groky routing rule is installed as a dormant template (`alwaysApply: false`). `cursor-st --groky` renders an active project-local copy and swaps the project-specific Sol/Terra/Luna links for Grok links. Normal `cursor-st` reverses that swap, keeping both Cursor hierarchies isolated.

See `cursor/GROKY.md` for the detailed contract.

### Codex — GPT Hierarchy v2

The home Codex hierarchy is Terra-led and escalation-based:

```text
Default:
  Terra Medium -> implement -> deterministic validation -> diff inspection -> done

Bounded support:
  Terra -> Luna -> Terra verifies/integrates -> validate -> done

Important:
  Terra -> validate -> Sol High review -> Terra fixes -> validate -> done

Architectural:
  Sol High architecture -> Terra implements -> validate -> Sol High review -> Terra fixes -> done

Exceptional:
  Terra attempts -> Sol High diagnosis -> Sol Max only if material uncertainty remains -> Terra implements
```

| Role | Model + effort | Responsibility |
| --- | --- | --- |
| Terra parent | `gpt-5.6-terra` + medium | Default task owner: inspect, plan normal work, implement, test, debug, integrate, self-review, finish |
| Luna worker | `gpt-5.6-luna` + medium | Optional bounded low-risk support |
| Terra reviewer | `gpt-5.6-terra` + high | Optional read-only routine second pass, mainly for Luna work |
| Sol architect | `gpt-5.6-sol` + high | Conditional read-only architecture and acceptance criteria |
| Sol reviewer | `gpt-5.6-sol` + high | Conditional read-only independent senior review |
| Sol Max advisor | `gpt-5.6-sol` + max | Exceptional read-only escalation |

The core rule is simple: Terra owns normal work. Luna is opportunistic. Sol High is conditional. Sol Max is exceptional. Deterministic validation should replace unnecessary model-on-model review whenever possible.

See `codex/HIERARCHY.md` for the routing contract and `codex/prompts/terra-led-workflow.md` for a reusable explicit execution prompt.

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

`doctor.sh --repo-only` checks shell syntax, JSON/TOML validity, Python compilation, and the repository scanner without modifying the live installation.

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

# Original Cursor hierarchy
cagent "Inspect this project and propose a plan."
cyolo "Implement the reviewed change and validate it."

# Composer + Grok Cursor hierarchy
groky-safe "Implement the requested change and validate it."
groky "Implement the reviewed change and validate it."

# Terra-led Codex hierarchy
codex-st "Implement the requested change and validate it."
codexy "Implement the reviewed change and validate it."
```

| Command | Behavior |
| --- | --- |
| `cagent` | Existing managed Sol-led Cursor workflow without adding `--yolo` |
| `cyolo` | Same Sol-led Cursor workflow with `--yolo` |
| `groky-safe` | Composer 2.5 + Grok 4.6 hierarchy with normal Cursor approval behavior |
| `groky` | Same Composer + Grok hierarchy with Cursor `--yolo` |
| `codex-st` | Managed Terra-led GPT Hierarchy v2 using the compatibility-named `sol-terra-luna` profile |
| `codexy` | Same GPT Hierarchy v2 with `--dangerously-bypass-approvals-and-sandbox` |
| `cdx` | Raw official `codex` command |

The Codex profile filename `sol-terra-luna.config.toml` is intentionally retained for compatibility with existing installs; its parent model and routing behavior are Terra-led GPT Hierarchy v2.

High-risk launchers change execution permissions, not model quality. Use `cyolo` and `groky` only in trusted projects. Use `codexy` only inside an external sandbox/trusted environment.

## Inspect the configured flows

```bash
cursor-st --show-flow
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

To validate, commit, and optionally push reviewed local changes through the repository helper:

```bash
./update-repo.sh --message "Describe the reviewed change"
./update-repo.sh --message "Describe the reviewed change" --include-codex --push
```

## Security

Never commit credentials, authentication JSON, private keys, `.env` files, sessions, logs, model history, local databases, machine trust entries, or other secrets. The scanner is a guardrail, not permission to commit sensitive material.

Repository validation proves internal consistency of the portable files; it does not prove account access, model availability, or that unrestricted execution is safe in a particular project.
