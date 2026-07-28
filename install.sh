#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
MODE=symlink
INCLUDE_CODEX=false
FORCE=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--symlink|--copy] [--include-codex|--skip-codex] [--force]
Default mode is --symlink and installs Cursor only.
EOF
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --copy) MODE=copy ;;
    --symlink) MODE=symlink ;;
    --include-codex) INCLUDE_CODEX=true ;;
    --skip-codex) INCLUDE_CODEX=false ;;
    --force) FORCE=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
require_command python3
python3 "$ROOT/lib/manage.py" scan "$ROOT"

BACKUP_DIR="$(backup_root)/$(timestamp)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
BASHRC="${HOME}/.bashrc"
ALIAS_TARGET="$(config_root)/ai-cli-aliases.sh"
HOOKS_TARGET="$CURSOR_HOME/hooks.json"

if [[ "$INCLUDE_CODEX" == true ]] && ! command -v codex >/dev/null 2>&1; then
  note "Codex is not installed; --include-codex will install only portable files."
fi

install_cursor() {
  local kind name source target
  for kind in agents rules; do
    for source in "$ROOT/cursor/$kind/"*; do
      name="$(basename -- "$source")"
      target="$CURSOR_HOME/$kind/$name"
      backup_existing "$target" "$BACKUP_DIR"
      install_item "$source" "$target" "$MODE" "$BACKUP_DIR" "$FORCE"
    done
  done
  backup_existing "$CURSOR_HOME/hooks/cursor-st-command-guard.py" "$BACKUP_DIR"
  install_item "$ROOT/cursor/hooks/cursor-st-command-guard.py" "$CURSOR_HOME/hooks/cursor-st-command-guard.py" "$MODE" "$BACKUP_DIR" "$FORCE"
  install_item "$ROOT/bin/cursor-st" "$HOME/.local/bin/cursor-st" "$MODE" "$BACKUP_DIR" "$FORCE"
  backup_existing "$ALIAS_TARGET" "$BACKUP_DIR"
  install_item "$ROOT/shell/ai-cli-aliases.sh" "$ALIAS_TARGET" "$MODE" "$BACKUP_DIR" "$FORCE"
  backup_existing "$HOOKS_TARGET" "$BACKUP_DIR"
  if [[ "$DRY_RUN" == true ]]; then
    note "dry-run: merge managed Cursor hook into $HOOKS_TARGET"
  else
    python3 "$ROOT/lib/manage.py" merge-hooks --destination "$HOOKS_TARGET" --template "$ROOT/cursor/hooks.json" --home "$HOME"
  fi
}

install_codex() {
  local codex_home="${CODEX_HOME:-$HOME/.codex}"
  local source target
  for source in "$ROOT/codex/AGENTS.md" "$ROOT/codex/rules/default.rules"; do
    target="$codex_home/${source#"$ROOT/codex/"}"
    backup_existing "$target" "$BACKUP_DIR"
    install_item "$source" "$target" "$MODE" "$BACKUP_DIR" "$FORCE"
  done
}

install_cursor
if [[ "$INCLUDE_CODEX" == true ]]; then install_codex; fi

backup_existing "$BASHRC" "$BACKUP_DIR"
replace_managed_block "$BASHRC" "local-bin" 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac'
replace_managed_block "$BASHRC" "aliases" 'source "$HOME/.config/ai-cli-dotfiles/ai-cli-aliases.sh"'

if [[ "$DRY_RUN" == false ]]; then
  ensure_dir "$(state_root)"
  manifest_tmp="$(mktemp)"
  record_item() {
    local source="$1" target="$2" actual_mode=copy
    [[ -L "$target" ]] && actual_mode=symlink
    printf '%s\t%s\t%s\n' "$actual_mode" "$source" "$target" >> "$manifest_tmp"
  }
  record_item "$ROOT/bin/cursor-st" "$HOME/.local/bin/cursor-st"
  record_item "$ROOT/shell/ai-cli-aliases.sh" "$ALIAS_TARGET"
  record_item "$ROOT/cursor/hooks/cursor-st-command-guard.py" "$CURSOR_HOME/hooks/cursor-st-command-guard.py"
  for local_source in "$ROOT/cursor/agents/"* "$ROOT/cursor/rules/"*; do
    record_item "$local_source" "$CURSOR_HOME/${local_source#"$ROOT/cursor/"}"
  done
  if [[ "$INCLUDE_CODEX" == true ]]; then
    record_item "$ROOT/codex/AGENTS.md" "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
    record_item "$ROOT/codex/rules/default.rules" "${CODEX_HOME:-$HOME/.codex}/rules/default.rules"
  elif [[ -f "$(manifest_path)" ]]; then
    while IFS=$'\t' read -r prior_mode prior_source prior_target; do
      [[ "$prior_source" == "$ROOT/codex/"* ]] && printf '%s\t%s\t%s\n' "$prior_mode" "$prior_source" "$prior_target" >> "$manifest_tmp"
    done < "$(manifest_path)"
  fi
  cp -- "$manifest_tmp" "$(manifest_path)"
  rm -f -- "$manifest_tmp"
  chmod 600 "$(manifest_path)"
  mkdir -p -- "$BACKUP_DIR"
  chmod 700 "$BACKUP_DIR"
  : > "$BACKUP_DIR/.complete"
fi

note "Installed ai-cli-dotfiles: mode=$MODE cursor=yes codex=$INCLUDE_CODEX"
note "Backups: $BACKUP_DIR"
note "Open a new Bash session or run: source \"$BASHRC\""
