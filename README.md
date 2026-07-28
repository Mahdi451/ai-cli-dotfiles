# AI CLI dotfiles

Private, portable Bash dotfiles for a Cursor CLI workflow on Ubuntu, WSL2, and
other Linux systems. The repository owns only its managed files, symlinks,
Cursor hook entry, and marked `.bashrc` blocks; it never replaces `agent` or
`codex`.

## Architecture

- `cursor/` holds the reviewed global Cursor agents, rules, hook template, and
  hook script.
- `bin/cursor-st` projects those global Cursor assets into the current project
  as ignored symlinks, then starts the official `agent` executable with Terra.
- `shell/` holds aliases installed at
  `~/.config/ai-cli-dotfiles/ai-cli-aliases.sh`.
- `codex/` is an opt-in portable framework. It excludes all authentication,
  history, sessions, logs, caches, and machine-specific trust state.
- `lib/manage.py` performs JSON hook merging and conservative secret scanning
  without additional dependencies.

The normal Cursor flow is Sol planner (read-only) → Terra implementation →
validation → Sol reviewer (read-only). Luna is reserved for large logs and
failure triage. Terra targets ordinary medium/default reasoning, but Cursor
controls the exact effort. Model-family availability varies by account, so
`doctor.sh` warns rather than rejecting a compatible alias.

## Daily commands

```bash
cyolo
cagent
cdoctor
```

These shortcuts expand to `cursor-st --yolo`, `cursor-st`, and
`cursor-st --doctor`. The official commands remain unchanged:

```bash
agent
codex
```

## Install

```bash
git clone <private-repository-url> ~/ai-cli-dotfiles
cd ~/ai-cli-dotfiles
./install.sh
source ~/.bashrc
./doctor.sh
```

The default uses symlinks. Existing affected files are copied to
`~/.local/state/ai-cli-dotfiles/backups/YYYYMMDD-HHMMSS/` before replacement.
Use `./install.sh --copy` for a self-contained installation, `--include-codex`
to install the safe Codex framework, and `--dry-run` to preview. Existing
unmanaged targets are refused unless `--force` is explicitly supplied.

The installer adds exactly these marked blocks to `.bashrc`:

```bash
# BEGIN AI-CLI-DOTFILES local-bin
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac
# END AI-CLI-DOTFILES local-bin
# BEGIN AI-CLI-DOTFILES aliases
source "$HOME/.config/ai-cli-dotfiles/ai-cli-aliases.sh"
# END AI-CLI-DOTFILES aliases
```

## Backup and update

`backup-current.sh` whitelists the portable Cursor assets, sanitizes the hook
template, scans a temporary staging directory, and then shows `git diff`.

```bash
./backup-current.sh
./update-repo.sh --message "Update Cursor agents and rules"
./update-repo.sh --message "Update Cursor agents and rules" --push
```

`--push` is required to push. The update script runs backup, secret scanning,
syntax checks, smoke tests, diff checks, commits, and verifies that the GitHub
remote is `PRIVATE` before pushing.

## Restore and uninstall

```bash
./uninstall.sh --dry-run
./uninstall.sh
./uninstall.sh --restore
```

The uninstaller removes only a symlink that still resolves to this repository
or a copied file that still matches its source. Changed or unrelated files are
preserved unless `--force` is supplied. In an interactive terminal it offers
to restore the most recent completed backup. It preserves Cursor/Codex
binaries and all login state.

## Cursor customization

Add agents under `cursor/agents/`, rules under `cursor/rules/`, and hook
scripts under `cursor/hooks/`. Update the installer whitelist when adding a
new managed Cursor file. `hooks.json` uses `__HOME__`, which is expanded only
when merged into the local user configuration. Do not add absolute paths.

## Future Codex support

Codex CLI 0.145.0 documents `~/.codex/config.toml`, but live config may mix
safe preferences with trusted paths or credentials. This repository therefore
stores only reviewable instructions, rules, prompts, and blank opt-in config
templates. `cdx` is a normal alias; `codexy` uses Codex's real
`--dangerously-bypass-approvals-and-sandbox` option and is dangerous. Codex
does not provide the inspected Cursor-style custom subagent setup, so use
explicit planning/review prompts instead.

## Secret policy

Never commit API keys, OAuth tokens, login state, `.env` files, private keys,
authentication caches, session cookies, shell history, certificates, or
machine-specific tokens. The `.gitignore` and scanner explicitly exclude
`~/.ssh`, `~/.aws`, `~/.config/gh/hosts.yml`, `.git-credentials`, and `.netrc`.
Scanner output reports only path, line number, and rule name—not values.

## Troubleshooting and migration

Run `./doctor.sh` after a Cursor update or on a new machine. It checks command
resolution, model availability, managed symlinks, JSON, shell syntax, secrets,
and `.bashrc` marker duplication. On a new WSL2/Linux machine, install Git,
Cursor CLI, and optionally Codex; authenticate each tool separately; clone
this private repository; then run the install commands above. If GitHub CLI
is not authenticated, run `gh auth login` and then:

```bash
cd ~/ai-cli-dotfiles && gh repo create ai-cli-dotfiles --private --source=. --remote=origin && git push -u origin main
```
