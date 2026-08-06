#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
FORCE=false
RESTORE=false

usage() { printf 'Usage: ./uninstall.sh [--dry-run] [--force] [--restore]\n'; }
while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    --force) FORCE=true ;;
    --restore) RESTORE=true ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
MANIFEST="$(manifest_path)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
BACKUP_DIR="$(backup_root)/$(timestamp)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
RESTORE_CANDIDATE=""
STATE_LOCKED=false
operation_lock
trap release_operation_lock EXIT
if [[ "$RESTORE" == false && -t 0 ]]; then
  read -r -p "Restore the most recent completed backup? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] && RESTORE=true
fi
if [[ "$RESTORE" == true ]]; then
  RESTORE_CANDIDATE="$(state_command latest --backup-root "$(backup_root)")"
fi
if [[ "$DRY_RUN" == false ]]; then
  state_command backup-init --backup-root "$(backup_root)" --backup-dir "$BACKUP_DIR"
fi

MANIFEST_TRUSTED=false
if trusted_manifest; then
  MANIFEST_TRUSTED=true
  while IFS=$'\t' read -r mode root_id asset target source; do
    if [[ "$mode" == copy && ! -f "$source" && -f "$ROOT/$asset" ]]; then
      source="$ROOT/$asset"
    fi
    backup_existing "$target" "$BACKUP_DIR"
    remove_managed_item "$source" "$target" "$mode" "$FORCE"
  done < <(state_command manifest)
elif [[ -e "$MANIFEST" || -L "$MANIFEST" ]]; then
  note "Invalid install manifest; managed file targets will be preserved. Reinstall to replace it safely."
else
  note "No install manifest found; file targets will be preserved."
fi

if [[ -L "$CURSOR_HOME/hooks.json" ]]; then
  if [[ "$FORCE" == true ]]; then
    backup_existing "$CURSOR_HOME/hooks.json" "$BACKUP_DIR"
    run rm -f -- "$CURSOR_HOME/hooks.json"
  else
    note "preserving hooks.json symlink: $CURSOR_HOME/hooks.json (use --force to back up and unlink)"
  fi
elif [[ -e "$CURSOR_HOME/hooks.json" ]]; then
  backup_existing "$CURSOR_HOME/hooks.json" "$BACKUP_DIR"
fi
backup_existing "$HOME/.bashrc" "$BACKUP_DIR"
if [[ "$DRY_RUN" == true ]]; then
  note "dry-run: remove managed Cursor hook and .bashrc blocks"
elif [[ ! -L "$CURSOR_HOME/hooks.json" ]]; then
  python3 "$ROOT/lib/manage.py" remove-hooks --destination "$CURSOR_HOME/hooks.json" --template "$ROOT/cursor/hooks.json" --cursor-home "$CURSOR_HOME"
fi
remove_managed_block "$HOME/.bashrc" "local-bin" 'case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac' "$FORCE"
remove_managed_block "$HOME/.bashrc" "aliases" 'source "${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles/ai-cli-aliases.sh"' "$FORCE"
if [[ "$DRY_RUN" == false && "$MANIFEST_TRUSTED" == true ]]; then
  rm -f -- "$MANIFEST"
  rm -f -- "$(source_registry_path)"
fi

restore_backup() {
  local backup="$1"
  [[ -n "$backup" ]] || { note "No completed backup is available."; return 0; }
  note "Restoring backup: $backup"
  restore_args=(restore --backup-root "$(backup_root)" --backup "$backup")
  [[ "$FORCE" == true ]] && restore_args+=(--force)
  [[ "$DRY_RUN" == true ]] && restore_args+=(--dry-run)
  state_command "${restore_args[@]}"
}

if [[ "$RESTORE" == true ]]; then restore_backup "$RESTORE_CANDIDATE"; fi
[[ "$DRY_RUN" == true ]] || state_command backup-complete --backup-root "$(backup_root)" --backup-dir "$BACKUP_DIR"
note "Uninstall complete. Cursor and Codex official binaries were not changed."
