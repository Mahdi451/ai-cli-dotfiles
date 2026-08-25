# Codex framework

Codex CLI loads its primary configuration from `~/.codex/config.toml`. This repository provides sanitized portable configuration, native agent definitions, global instructions, and guarded launchers without importing credentials, history, login state, trust entries, notices, caches, or other machine-local state.

## GPT Hierarchy v2

The optimized home workflow is Terra-led and escalation-based:

```text
Default:
  Terra Medium -> implement -> deterministic validation -> diff inspection -> done

Bounded cheap support:
  Terra -> Luna -> Terra verify/integrate -> validate -> done

Important:
  Terra -> validate -> Sol High review -> Terra fixes -> validate -> done

Architectural:
  Sol High architecture -> Terra implementation -> validate -> Sol High review -> Terra fixes -> done

Exceptional:
  Terra attempts -> Sol High diagnosis -> Sol Max only if substantial uncertainty remains -> Terra implements
```

Roles:

- Terra Medium: primary parent and normal task owner.
- Luna Medium: optional bounded, low-risk support only.
- Terra High: optional read-only routine second pass, mainly for Luna work.
- Sol High architect: conditional read-only architecture/acceptance criteria.
- Sol High reviewer: conditional read-only independent senior review.
- Sol Max (`sol_planner`): exceptional read-only escalation advisor.

See `HIERARCHY.md` for the full routing contract.

A reusable explicit task prompt lives at `prompts/terra-led-workflow.md`.

## Installation behavior

`install.sh` installs `AGENTS.md`, `rules/default.rules`, all portable agent TOMLs, the sanitized base template, the compatibility-named `sol-terra-luna.config.toml`, and `codex-st`.

The `sol-terra-luna` profile filename is intentionally retained for compatibility with existing installations. Its behavior is now GPT Hierarchy v2 and its parent model is Terra Medium.

The official `codex` executable remains untouched. `cdx` and `codex` are raw Codex. `codex-st` selects the managed compatibility profile, blocks model/profile/configuration overrides that could bypass it, and forwards normal arguments and subcommands.

`codexy` runs:

```bash
codex-st --dangerously-bypass-approvals-and-sandbox
```

It uses the same Terra-led hierarchy but bypasses approvals and sandboxing. Use it only in an externally sandboxed/trusted environment.

## Model mapping

| Role | Codex model | Reasoning |
| --- | --- | --- |
| Terra parent | `gpt-5.6-terra` | `medium` |
| Luna bounded worker | `gpt-5.6-luna` | `medium` |
| Terra routine reviewer | `gpt-5.6-terra` | `high` |
| Sol architect | `gpt-5.6-sol` | `high` |
| Sol reviewer | `gpt-5.6-sol` | `high` |
| Sol Max escalation | `gpt-5.6-sol` | `max` |

## Useful commands

```bash
codex-st --show-flow
codex-st --doctor
codex-st "Implement the requested change and validate it."
codexy "Implement the reviewed change and validate it."
```

The hierarchy is deliberately conditional. Routine work should usually remain in one Terra context. Sol review is reserved for consequential work, and Luna is used only when delegation is genuinely cheaper than keeping the task with Terra.