# AI CLI dotfiles

This repository sets up a portable Linux/WSL workflow for the official Cursor
and Codex CLIs. It installs reviewed instructions, role definitions, guarded
launchers, selected preferences, and shell aliases. It does not install either
CLI, sign you in, or put credentials, history, sessions, or caches in Git.

## Overview: model workflow

The workflow gives Sol High responsibility for planning and final signoff,
with Terra as the usual implementation agent and Luna limited to explicitly
bounded, low-risk support.

```text
Sol High: inspect, plan, set acceptance criteria, review the complete diff,
          and give final signoff
  └─ Terra Medium: ordinary implementation, tests, debugging, and integration
       └─ Luna Medium: explicitly bounded, low-risk support only
  └─ Terra High: read-only routine/advisory review, especially of Luna work
  └─ Sol Max: read-only escalation advisor for architecture, security,
              unusually difficult reasoning, stalled debugging, or a
              fundamental review finding
```

This is a set of instructions and role definitions, not a deterministic model
router. Sol High must still choose and scope any delegation, and is the only
role that gives final signoff.

| Role | Cursor model form | Codex model + reasoning | Responsibility |
| --- | --- | --- | --- |
| Sol High parent | `gpt-5.6-sol-high` | `gpt-5.6-sol` + `high` | Planning, acceptance, complete-diff review, final signoff |
| Terra Medium | `gpt-5.6-terra-medium` | `gpt-5.6-terra` + `medium` | Default ordinary implementation and tests |
| Luna Medium | `gpt-5.6-luna-medium` | `gpt-5.6-luna` + `medium` | Explicit bounded low-risk work |
| Terra High reviewer | `gpt-5.6-terra-high` | `gpt-5.6-terra` + `high` | Read-only advisory review |
| Sol Max advisor | `gpt-5.6-sol-max` | `gpt-5.6-sol` + `max` | Read-only escalation-only advice |

Cursor uses combined catalog slugs in `cursor-st`. Its portable preferences
use a base model and a separate reasoning parameter. Codex uses separate
`model` and `model_reasoning_effort` settings. Before changing a Cursor pin,
run `agent models` and use an ID available to your signed-in account.

## Prerequisites

Use Linux or WSL with Bash, Python 3.11 or newer, and Git. Install and sign in
to the official Cursor CLI (`agent` or `cursor-agent`) if you will use Cursor,
and the official `codex` executable if you will use Codex. `rg` is needed for
the smoke test and backup workflow.

Clone your private repository and enter it:

```bash
git clone git@github.com:YOUR-ACCOUNT/ai-cli-dotfiles.git
cd ai-cli-dotfiles
```

## Repo-only preflight

Before making any changes outside the repository, validate the portable
content:

```bash
./doctor.sh --repo-only
git diff --check
```

This checks script syntax, JSON and TOML, Python compilation, and the secret
scanner. It does not require an installed setup or a signed-in CLI.

## Dry run, then install

Preview first:

```bash
./install.sh --dry-run
```

The dry run previews shell-file mutations and does not publish install state
or a backup. When the preview is acceptable, perform the normal symlink
installation:

```bash
./install.sh
source ~/.bashrc
./doctor.sh
```

Symlinks are the default, so later reviewed repository changes are reflected
by the installed portable files. The installer creates timestamped backups
before changes, merges Cursor hooks and selected preferences rather than
replacing them wholesale, and preserves an already present Codex
`config.toml` unless asked to replace it.

### Optional installation choices

| Choice | Command | Effect |
| --- | --- | --- |
| Independent files | `./install.sh --copy` | Copy portable assets instead of symlinking them. |
| Cursor only | `./install.sh --cursor-only` | Install Cursor assets and common aliases while retaining recorded Codex assets. |
| Codex only | `./install.sh --codex-only` | Install Codex assets and common aliases while retaining recorded Cursor assets. |
| Replace Codex base config | `./install.sh --replace-config` | Back up then replace `~/.codex/config.toml` with the sanitized template. |
| Replace a protected target | `./install.sh --force` | Back up and replace an unrecognized or changed target. |
| Store unrestricted Cursor preferences | `./install.sh --full-access` | Write Cursor unrestricted approvals and disabled sandbox preferences. |

`--cursor-only --codex-only` is invalid. `--full-access` requires Cursor and
cannot be combined with `--codex-only`; `--replace-config` cannot be combined
with `--cursor-only`.

`./install.sh --full-access` changes stored Cursor preferences. It is separate
from choosing `cyolo` for one Cursor invocation: it does not make every
launch use `--yolo`, and `cyolo` does not store preference changes. Review the
risk of each choice independently.

## Everyday launchers

Open a new shell after installation, or run `source ~/.bashrc`. Start each
tool from the project you want to work in:

```bash
cd ~/projects/example-app
cagent "Inspect this project and propose a plan."
codex-st "Implement the accepted plan and run focused tests."
```

| Command | What it does | Use it when |
| --- | --- | --- |
| `cagent` | Runs `cursor-st` without adding Cursor `--yolo`. The wrapper starts the Sol High parent and maintains the stated hierarchy; effective permissions follow stored Cursor preferences. | Standard Cursor work without per-invocation `--yolo`. |
| `cyolo` | Runs `cursor-st --yolo`, using the same Sol High hierarchy with Cursor `--yolo`. | Only in a trusted project after reviewing the scope. |
| `codex-st` | Runs Codex with the named `sol-terra-luna` profile and hierarchy, without adding the dangerous bypass flag. | Standard profile-based Codex work. |
| `codexy` | Runs `codex-st --dangerously-bypass-approvals-and-sandbox`, with the same hierarchy. | Only inside an external sandbox. |
| `cdx` | Runs the raw official `codex` command. It does not explicitly select the named profile. | When you intentionally need raw Codex behavior. |

`cyolo` and `codexy` change execution permissions, not model quality or the
orchestration design. The guarded wrappers reject model and configuration
overrides that would bypass their hierarchy. The raw official commands remain
available and untouched.

### High-risk launchers

Use these only after reviewing the project and requested scope. `cyolo` adds
Cursor `--yolo`; `codexy` bypasses Codex approvals and sandboxing. They retain
the same hierarchy and do not improve model quality or orchestration.

```bash
cd ~/projects/example-app
cyolo "Make the reviewed change and run its focused tests."
codexy "Apply the accepted change and verify it."
```

Use `cyolo` only in a trusted project. Use `codexy` only inside an external
sandbox.

Useful checks and project cleanup commands:

```bash
cursor-st --show-flow
codex-st --show-flow
cdoctor
cursor-st --clean-project
```

`cursor-st` creates matching managed `.cursor` links in the project it starts
from, and `--clean-project` removes only those matching links.

## Exact mappings

`CURSOR_HOME` and `CODEX_HOME` can redirect the Cursor and Codex destinations.
State and configuration paths honor `XDG_STATE_HOME` and `XDG_CONFIG_HOME`.

| Repository source | Installed destination |
| --- | --- |
| `cursor/agents/*.md` | `~/.cursor/agents/` |
| `cursor/rules/*.mdc` | `~/.cursor/rules/` |
| `cursor/hooks/cursor-st-command-guard.py` | `~/.cursor/hooks/cursor-st-command-guard.py` |
| `cursor/statusline.py` | `~/.cursor/statusline.py` |
| `cursor/hooks.json` | merged into `~/.cursor/hooks.json` |
| `cursor/cli-config.json` | selected portable fields merged into `~/.cursor/cli-config.json` |
| `bin/cursor-st` | `~/.local/bin/cursor-st` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `codex/rules/default.rules` | `~/.codex/rules/default.rules` |
| `codex/config/sol-terra-luna.config.toml` | `~/.codex/sol-terra-luna.config.toml` |
| `codex/agents/*.toml` | `~/.codex/agents/` |
| `codex/config/config.toml` | `~/.codex/config.toml`, only if missing or `--replace-config` is used |
| `bin/codex-st` | `~/.local/bin/codex-st` |
| `shell/ai-cli-aliases.sh` | `${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles/ai-cli-aliases.sh` |
| Managed shell blocks | `~/.bashrc`: add `~/.local/bin` to `PATH` and source the aliases |

## Maintenance and recovery

Use these commands from the repository:

```bash
./doctor.sh --repo-only
./tests/smoke-test.sh
git diff --check
./uninstall.sh --dry-run
./uninstall.sh --restore
```

`./doctor.sh` without `--repo-only` additionally validates a recognized
managed installation. `uninstall.sh` removes only manifest-recognized,
unchanged managed files; `--restore` restores the most recent completed
backup. Review `--force` carefully because it permits replacement or removal
of protected targets.

To capture a reviewed portable Cursor configuration, run:

```bash
./backup-current.sh
```

Add `--include-codex` to capture the portable Codex framework and a sanitized
Codex configuration. Inspect the Git diff before committing. For an
intentional capture, validation, commit, and optional private push:

```bash
./update-repo.sh --message "Describe the reviewed change"
./update-repo.sh --message "Describe the reviewed change" --include-codex --push
```

## Customization

Make changes in this repository, not in an installed copy. Keep
machine-specific paths, authentication data, sessions, tokens, and caches out
of the repository. Preserve the routing and safety rules unless you have
reviewed a deliberate policy change.

For Cursor, use the provided Markdown agent and rule structure. For Codex,
use native TOML agent files; do not copy Cursor agents into `~/.codex`. After
any change, run the repo-only doctor, smoke test, and `git diff --check`, then
review the complete diff before installing.

## Troubleshooting and security

| Symptom | What to do |
| --- | --- |
| Cursor CLI not found | Install the official CLI so `agent` or `cursor-agent` is on `PATH`. |
| Codex CLI not found | Install the official `codex` executable and ensure it is on `PATH`. |
| Cursor cannot use a model | Run `agent models` and use an available catalog ID. |
| A wrapper rejects `--model`, `--profile`, or configuration overrides | Expected: use the raw official command for a deliberate different setup, or change this repository through review. |
| Installer refuses a target | It protects an unmanaged or changed file. Inspect it, preserve it, choose another destination, or use `--force` only after backup and review. |
| Codex base configuration did not change | Expected unless it was missing or you used `--replace-config`. |
| Full access is missing | Normal installation omits it. Re-run the Cursor installation with `--full-access` only after accepting the risk. |
| Project links are stale | Run `cursor-st --clean-project` there, then launch through `cursor-st` again if needed. |

Never commit credentials, authentication JSON, private keys, environment
files, sessions, logs, model history, or local databases. The repository's
scanner is a guardrail, not permission to commit sensitive material. Redact
examples and inspect `git diff` before every commit or push.

Repository checks prove the portable scripts and configuration are internally
consistent. They do not prove account access, provider acceptance of every
model, or that unrestricted execution is safe in a particular environment.
