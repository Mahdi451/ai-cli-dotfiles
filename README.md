# AI CLI dotfiles

This repository is the portable, reviewable source of truth for one Linux/WSL
Cursor and Codex workflow. It installs workflow instructions, agent roles,
launchers, a small set of preferences, and shell aliases. It does **not**
install Cursor or Codex themselves, sign either tool in, or copy private
machine history into Git.

The intended hierarchy is:

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

This is a guided workflow expressed in instructions and role definitions, not
a deterministic model router. The parent must choose and scope delegation.
Sol High alone gives final signoff.

## Read this first: live installation versus this rebuilt checkout

There are currently two checkouts on this machine:

| Location | Status | Ownership |
| --- | --- | --- |
| `/home/mahdiosx/ai-cli-dotfiles` | Existing live checkout | Current live `cursor-st` and `codex-st` resolve here. Do not casually delete or overwrite it. |
| `/home/mahdiosx/projects/ai-cli-dotfiles` | Rebuilt repository | The source documented here. It is not yet the owner of the existing live installation. |

The rebuilt scripts use a relocation-safe version-2 install manifest and a
source registry under `${XDG_STATE_HOME:-$HOME/.local/state}/ai-cli-dotfiles/`.
They refuse unsafe or invalid state. That is intentional: a malformed or
legacy install must not be silently adopted and then removed by an unrelated
checkout.

For the current old live setup, start with `./doctor.sh`. If it reports invalid
or unsafe legacy metadata, stop. There is no supported in-place migration from
that legacy state in this rebuild. Preserve the old checkout and its backups;
use a separately reviewed migration/cleanup procedure before trying to make
this checkout live. A fresh installation into a clean home, or an installation
whose manifest is already valid, is supported.

## What belongs in Git

The repository contains only portable, auditable material:

```text
.
├── install.sh / uninstall.sh / doctor.sh / backup-current.sh / update-repo.sh
├── bin/                 # guarded Cursor and Codex launchers
├── cursor/
│   ├── agents/          # four Cursor role instructions
│   ├── rules/           # workflow and safety rules
│   ├── hooks/           # command guard
│   ├── cli-config.json  # portable preference allowlist
│   └── statusline.py
├── codex/
│   ├── AGENTS.md        # global Codex workflow instructions
│   ├── agents/          # native TOML role definitions
│   ├── config/          # sanitized base and named profile templates
│   ├── rules/           # reusable Codex rules
│   └── prompts/         # place for reusable prompt text
├── shell/               # aliases loaded from .bashrc
├── lib/                 # install, state, merge, and secret-scan helpers
├── templates/           # starting points for new local assets
└── tests/smoke-test.sh  # isolated install/restore safety test
```

It deliberately excludes auth, account/team data, login state, sessions,
model-selection history, plans, telemetry/tracking data, caches, logs,
SQLite/databases, project trust, notices, migrations, and secret files. The
backup command also sanitizes Cursor model metadata so stale display labels,
aliases, context limits, and selection history do not become portable state.

## Requirements and safety model

Use Linux or WSL with Bash, Python 3 (Python 3.11+ is needed to validate TOML),
Git for `update-repo.sh`, and the official Cursor CLI (`agent` or
`cursor-agent`) and/or official `codex` executable already installed and
logged in as appropriate. `rg` is used by the smoke test and backup workflow.

The repository changes only its documented targets and marked `.bashrc`
blocks. Before replacing a target it makes a timestamped backup. It refuses to
replace an existing unrelated target unless `--force` is given. Cursor hooks
and preferences are merged rather than wholesale replaced; existing unknown
runtime settings, including authentication, remain intact. Codex
`~/.codex/config.toml` is preserved unless you explicitly ask to replace it.

`--full-access` is intentionally separate from normal installation. It writes
Cursor's unrestricted approval mode and disabled sandbox preference. Use it
only when unrestricted tool execution is genuinely intended. `codexy` is even
more powerful: it bypasses Codex approvals and sandboxing, and is appropriate
only inside an externally sandboxed environment.

## Exact installation mapping

Defaults can be redirected with `CURSOR_HOME` and `CODEX_HOME`; state and
configuration respect `XDG_STATE_HOME` and `XDG_CONFIG_HOME`.

| Repository source | Installed destination |
| --- | --- |
| `cursor/agents/*.md` | `~/.cursor/agents/` |
| `cursor/rules/*.mdc` | `~/.cursor/rules/` |
| `cursor/hooks/cursor-st-command-guard.py` | `~/.cursor/hooks/cursor-st-command-guard.py` |
| `cursor/statusline.py` | `~/.cursor/statusline.py` |
| `cursor/hooks.json` | merged into `~/.cursor/hooks.json` |
| `cursor/cli-config.json` | selected safe fields merged into `~/.cursor/cli-config.json` |
| `bin/cursor-st` | `~/.local/bin/cursor-st` |
| `codex/AGENTS.md` | `~/.codex/AGENTS.md` |
| `codex/rules/default.rules` | `~/.codex/rules/default.rules` |
| `codex/config/sol-terra-luna.config.toml` | `~/.codex/sol-terra-luna.config.toml` |
| `codex/agents/*.toml` | `~/.codex/agents/` |
| `codex/config/config.toml` | `~/.codex/config.toml`, only if missing or `--replace-config` is used |
| `bin/codex-st` | `~/.local/bin/codex-st` |
| `shell/ai-cli-aliases.sh` | `${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles/ai-cli-aliases.sh` |
| two marked blocks | `~/.bashrc`: ensure `~/.local/bin` is on `PATH`, then source aliases |

By default these are symlinks. `--copy` makes independent copies instead.
Either form is recorded in the install manifest so that safe uninstall and
restore can distinguish managed content from user changes.

## Models and delegation

Cursor and Codex describe the same hierarchy differently.

| Role | Cursor model form | Codex model + reasoning | Responsibility |
| --- | --- | --- | --- |
| Sol High parent | `gpt-5.6-sol-high` | `gpt-5.6-sol` + `high` | Planning, acceptance, complete-diff review, final signoff |
| Terra Medium | `gpt-5.6-terra-medium` | `gpt-5.6-terra` + `medium` | Default ordinary implementation and tests |
| Luna Medium | `gpt-5.6-luna-medium` | `gpt-5.6-luna` + `medium` | Explicit bounded low-risk work |
| Terra High reviewer | `gpt-5.6-terra-high` | `gpt-5.6-terra` + `high` | Read-only advisory review |
| Sol Max advisor | `gpt-5.6-sol-max` | `gpt-5.6-sol` + `max` | Read-only, escalation-only advice |

Cursor uses combined catalog slugs in `cursor-st`, while its portable
`cli-config.json` stores the base model plus a separate `reasoning` parameter.
Codex likewise uses separate `model` and `model_reasoning_effort` settings.
That difference is deliberate; do not paste Cursor's combined slugs into
Codex TOML. Before changing Cursor model pins, run `agent models` and use the
exact model IDs available to the signed-in account.

`cursor-st` always launches the Sol High parent and rejects caller-supplied
`--model`. It leaves Cursor's `exploreSubagentModel` as `default`. Codex's
named `sol-terra-luna` profile makes an **unnamed** Codex subagent default to
Terra Medium; its four native role TOMLs define the other roles. Neither fact
removes the parent's responsibility to follow the role instructions and choose
the correct delegation.

## Install

From the rebuilt repository, after the live-state warning above has been
resolved:

```bash
./install.sh
./doctor.sh
source ~/.bashrc
```

`install.sh` supports every option below.

| Command or flag | Meaning |
| --- | --- |
| `./install.sh` | Install Cursor and Codex portable assets as symlinks. |
| `--symlink` | Explicit default: link installed assets to this checkout. |
| `--copy` | Copy assets instead of linking them. |
| `--cursor-only` | Install Cursor assets plus the common aliases; retain recorded Codex assets. |
| `--codex-only` | Install Codex assets plus the common aliases; retain recorded Cursor assets. |
| `--full-access` | When Cursor is included, write unrestricted Cursor approvals and disabled sandbox. |
| `--replace-config` | When Codex is included, back up then replace `~/.codex/config.toml` with the sanitized template. |
| `--force` | Back up and replace an existing target that is not recognized as matching managed content. |
| `--dry-run` | Preview shell-file mutations; no install state or backup is published. |
| `-h` / `--help` | Show usage. |

`--cursor-only --codex-only` is invalid. So are `--full-access` with
`--codex-only`, and `--replace-config` with `--cursor-only`. A normal install
does not enable full access and does not replace an existing Codex config.

## Everyday commands

After opening a new shell (or sourcing `~/.bashrc`):

| Command | What it does |
| --- | --- |
| `cyolo` | Run `cursor-st --yolo`; the Cursor wrapper sets up per-project managed links and uses Sol High. |
| `cagent` | Run `cursor-st` without adding Cursor's `--yolo`. |
| `cdoctor` | Run the Cursor workflow check. |
| `cdx` | Run the official raw `codex` command. |
| `codex-st` | Run Codex with the protected `sol-terra-luna` profile. |
| `codexy` | Run `codex-st --dangerously-bypass-approvals-and-sandbox`; use only in an external sandbox. |
| `cursor-st --show-flow` / `codex-st --show-flow` | Print the intended roles and flow. |
| `cursor-st --clean-project` | Remove only matching Cursor project links created by the wrapper. |

The wrappers reject model/profile/config/provider overrides that would bypass
their hierarchy. The official `agent`/`cursor-agent` and `codex` commands stay
untouched.

## Back up, diagnose, update, uninstall, and restore

Before capturing a known-good live Cursor configuration:

```bash
./backup-current.sh
```

This requires every listed portable Cursor source to exist and writes them
into the working tree after a temporary staging scan. To also capture the
portable Codex framework and a sanitized Codex config, use:

```bash
./backup-current.sh --include-codex
```

It has only `--include-codex`, `-h`, and `--help`; it does not have a dry-run.
Always inspect the resulting Git diff before committing.

For checks:

```bash
./doctor.sh --repo-only   # syntax, JSON, TOML, Python compile, secret scan
./doctor.sh               # also validate a recognized installed setup
./tests/smoke-test.sh     # isolated install, upgrade, restore, and safety tests
git diff --check
```

For an intentional capture, validation, commit, and optional private push:

```bash
./update-repo.sh --message "Describe the reviewed change"
./update-repo.sh --message "Describe the reviewed change" --include-codex --push
```

`--message` is required. `--include-codex` passes through to the backup step;
`--push` verifies that the GitHub remote is private before pushing. This script
stages only the documented repository paths, but it can commit already changed
portable files, so review the diff first.

To remove managed assets:

```bash
./uninstall.sh --dry-run
./uninstall.sh --restore
```

`uninstall.sh` supports `--dry-run`, `--force`, `--restore`, `-h`, and
`--help`. Without `--restore`, it asks interactively whether to restore the
latest completed backup when stdin is a terminal. It removes only manifest
recognized, unchanged managed files. A changed file or changed marked
`.bashrc` block is preserved; use `--force` only after reviewing what will be
overwritten or removed. `--restore` restores the most recent completed backup;
an interrupted install's incomplete backup is deliberately ignored.

## Customization without losing the safety boundary

1. Make a small change in this repository, not directly in a live installed
   copy.
2. Keep machine-specific paths, auth, sessions, tokens, and caches out of the
   change.
3. For Cursor, use the supplied agent and rule templates and preserve the
   current model-routing safety rules. For Codex, use native TOML agent files;
   do not transplant Cursor Markdown agents into `~/.codex`.
4. Validate with `./doctor.sh --repo-only`, `./tests/smoke-test.sh`, and
   `git diff --check`.
5. Review the complete diff, then install from the intended checkout. Use
   `--replace-config`, `--force`, or `--full-access` only when that exact
   behavior was reviewed.

## Troubleshooting

| Symptom | What to do |
| --- | --- |
| `Cursor CLI not found` | Install the official CLI so `agent` or `cursor-agent` is on `PATH`. |
| `Codex CLI not found` | Install the official `codex` executable and ensure it is on `PATH`. |
| `Cannot use this model` | Run `agent models`; use the exact current Cursor catalog ID. Do not use bracketed effort syntax in a Cursor slug. |
| Wrapper refuses `--model`, `--profile`, or config overrides | Expected. Run the raw official command when you intentionally need a different configuration, or change this repository through review. |
| Installer refuses an existing target | It protects an unmanaged or changed file. Inspect it, then either preserve it, choose a new target/home, or use `--force` after backup. |
| Existing Codex configuration did not change | Expected. Use `--replace-config` only if replacing it is truly intended. |
| Doctor says manifest/state is invalid or unsafe | Stop. Do not force reinstall or uninstall. Preserve the old checkout/backups and use a separately reviewed migration. |
| Full access is missing | Normal install omits those settings. Re-run the Cursor installation with `--full-access` only if the risk is acceptable. |
| Project has stale Cursor global links | Run `cursor-st --clean-project` from that project, then launch through `cursor-st` again if needed. |

## Secret policy

Never commit credentials, auth JSON, private keys, environment files, sessions,
logs, model history, or local database files. `.gitignore` blocks common forms,
and `python3 lib/manage.py scan .` is run by the doctor and update paths, but
the scan is a guardrail rather than permission to commit sensitive material.
Redact examples and inspect `git diff` before every commit or push.

## Verification standard

Repository validation proves that scripts and portable configuration are
consistent in isolated test homes. It does not prove that the official Cursor
or Codex backend accepts a model for every account, that a user is logged in,
or that unrestricted execution is safe on a particular machine. Run the
appropriate official CLI checks after installation, and treat live backend and
full-access use as a separate acceptance decision.
