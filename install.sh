#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false MODE=symlink INSTALL_CURSOR=true INSTALL_CODEX=true FORCE=false FULL_ACCESS=false REPLACE_CONFIG=false CONFIG_MANAGED=false
usage() {
  cat <<'EOF'
Usage: ./install.sh [--symlink|--copy] [--cursor-only|--codex-only] [--full-access] [--replace-config] [--force] [--dry-run]
Installs both portable Cursor and Codex assets by default. --full-access is required
to write Cursor's unrestricted approval and disabled sandbox preferences.
EOF
}
while (($#)); do case "$1" in
  --dry-run) DRY_RUN=true;; --copy) MODE=copy;; --symlink) MODE=symlink;;
  --cursor-only) INSTALL_CODEX=false;; --codex-only) INSTALL_CURSOR=false;;
  --full-access) FULL_ACCESS=true;; --replace-config) REPLACE_CONFIG=true;;
  --force) FORCE=true;; -h|--help) usage; exit 0;; *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2;; esac; shift; done
[[ "$INSTALL_CURSOR" == true || "$INSTALL_CODEX" == true ]] || { printf '%s\n' 'Cannot combine --cursor-only and --codex-only.' >&2; exit 2; }
[[ "$INSTALL_CURSOR" == true || "$FULL_ACCESS" == false ]] || { printf '%s\n' '--full-access requires Cursor installation.' >&2; exit 2; }
[[ "$INSTALL_CODEX" == true || "$REPLACE_CONFIG" == false ]] || { printf '%s\n' '--replace-config requires Codex installation.' >&2; exit 2; }
ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
source "$ROOT/lib/common.sh"
require_command python3
python3 "$ROOT/lib/manage.py" scan "$ROOT"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}" CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BACKUP_DIR="$(backup_root)/$(timestamp)"
STATE_LOCKED=false; operation_lock; trap release_operation_lock EXIT
[[ "$DRY_RUN" == true ]] || { state_command preflight; state_command backup-init --backup-root "$(backup_root)" --backup-dir "$BACKUP_DIR"; }

install_asset() {
  local source="$1" target="$2"
  backup_existing "$target" "$BACKUP_DIR"
  install_item "$source" "$target" "$MODE" "$BACKUP_DIR" "$FORCE"
}
if [[ "$INSTALL_CURSOR" == true ]]; then
  for source in "$ROOT"/cursor/agents/*.md "$ROOT"/cursor/rules/*.mdc; do
    install_asset "$source" "$CURSOR_HOME/${source#"$ROOT/cursor/"}"
  done
  for retired in grok-advisor.md grok-architect.md; do
    target="$CURSOR_HOME/agents/$retired"
    [[ -e "$target" || -L "$target" ]] || continue
    backup_existing "$target" "$BACKUP_DIR"
    [[ "$DRY_RUN" == true ]] || rm -f -- "$target"
  done
  install_asset "$ROOT/cursor/hooks/cursor-st-command-guard.py" "$CURSOR_HOME/hooks/cursor-st-command-guard.py"
  install_asset "$ROOT/cursor/statusline.py" "$CURSOR_HOME/statusline.py"
  install_asset "$ROOT/bin/cursor-st" "$HOME/.local/bin/cursor-st"
  backup_existing "$CURSOR_HOME/hooks.json" "$BACKUP_DIR"
  [[ "$DRY_RUN" == true ]] || python3 "$ROOT/lib/manage.py" merge-hooks --destination "$CURSOR_HOME/hooks.json" --template "$ROOT/cursor/hooks.json" --cursor-home "$CURSOR_HOME"
  backup_existing "$CURSOR_HOME/cli-config.json" "$BACKUP_DIR"
  [[ "$DRY_RUN" == true ]] || python3 "$ROOT/lib/manage.py" merge-cursor-config --destination "$CURSOR_HOME/cli-config.json" --template "$ROOT/cursor/cli-config.json" --cursor-home "$CURSOR_HOME" $([[ "$FULL_ACCESS" == true ]] && printf '%s' --full-access)
fi
if [[ "$INSTALL_CODEX" == true ]]; then
  for source in "$ROOT/codex/AGENTS.md" "$ROOT/codex/rules/default.rules" "$ROOT/codex/config/sol-terra-luna.config.toml" "$ROOT/codex/agents/"*.toml "$ROOT/bin/codex-st"; do
    case "$source" in
      "$ROOT/codex/AGENTS.md") target="$CODEX_HOME/AGENTS.md";;
      "$ROOT/codex/rules/"*) target="$CODEX_HOME/rules/$(basename "$source")";;
      "$ROOT/codex/config/"*) target="$CODEX_HOME/$(basename "$source")";;
      "$ROOT/codex/agents/"*) target="$CODEX_HOME/agents/$(basename "$source")";;
      *) target="$HOME/.local/bin/codex-st";;
    esac
    install_asset "$source" "$target"
  done
  if [[ ! -e "$CODEX_HOME/config.toml" && ! -L "$CODEX_HOME/config.toml" ]]; then
    install_asset "$ROOT/codex/config/config.toml" "$CODEX_HOME/config.toml"
    CONFIG_MANAGED=true
  elif [[ "$REPLACE_CONFIG" == true ]]; then
    backup_existing "$CODEX_HOME/config.toml" "$BACKUP_DIR"
    install_item "$ROOT/codex/config/config.toml" "$CODEX_HOME/config.toml" "$MODE" "$BACKUP_DIR" true
    CONFIG_MANAGED=true
  else
    note "Preserving existing Codex config.toml (use --replace-config to replace after backup)."
  fi
fi
install_asset "$ROOT/shell/ai-cli-aliases.sh" "$(config_root)/ai-cli-aliases.sh"
backup_existing "$HOME/.bashrc" "$BACKUP_DIR"
replace_managed_block "$HOME/.bashrc" local-bin 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'
replace_managed_block "$HOME/.bashrc" aliases 'source "${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles/ai-cli-aliases.sh"'
if [[ "$DRY_RUN" == false ]]; then
  records="$(mktemp)"
  record() { local s="$1" t="$2" mode=copy; [[ -L "$t" ]] && mode=symlink; printf '%s\t%s\t%s\n' "$mode" "${s#"$ROOT/"}" "$t" >> "$records"; }
  record "$ROOT/shell/ai-cli-aliases.sh" "$(config_root)/ai-cli-aliases.sh"
  [[ "$INSTALL_CURSOR" == true ]] && { record "$ROOT/bin/cursor-st" "$HOME/.local/bin/cursor-st"; record "$ROOT/cursor/hooks.json" "$CURSOR_HOME/hooks.json"; record "$ROOT/cursor/hooks/cursor-st-command-guard.py" "$CURSOR_HOME/hooks/cursor-st-command-guard.py"; record "$ROOT/cursor/statusline.py" "$CURSOR_HOME/statusline.py"; record "$ROOT/cursor/cli-config.json" "$CURSOR_HOME/cli-config.json"; for s in "$ROOT"/cursor/agents/*.md "$ROOT"/cursor/rules/*.mdc; do record "$s" "$CURSOR_HOME/${s#"$ROOT/cursor/"}"; done; }
  [[ "$INSTALL_CODEX" == true ]] && { record "$ROOT/bin/codex-st" "$HOME/.local/bin/codex-st"; record "$ROOT/codex/AGENTS.md" "$CODEX_HOME/AGENTS.md"; record "$ROOT/codex/rules/default.rules" "$CODEX_HOME/rules/default.rules"; record "$ROOT/codex/config/sol-terra-luna.config.toml" "$CODEX_HOME/sol-terra-luna.config.toml"; [[ "$CONFIG_MANAGED" == true ]] && record "$ROOT/codex/config/config.toml" "$CODEX_HOME/config.toml"; for s in "$ROOT"/codex/agents/*.toml; do record "$s" "$CODEX_HOME/agents/$(basename "$s")"; done; }
  publish=(publish --records "$records")
  [[ "$INSTALL_CURSOR" == false ]] && publish+=(--retain-cursor)
  [[ "$INSTALL_CODEX" == false ]] && publish+=(--retain-codex)
  state_command "${publish[@]}"; rm -f "$records"
  state_command backup-complete --backup-root "$(backup_root)" --backup-dir "$BACKUP_DIR"
fi
note "Installed portable assets: cursor=$INSTALL_CURSOR codex=$INSTALL_CODEX mode=$MODE"
note "Backups: $BACKUP_DIR"
