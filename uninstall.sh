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

if [[ -f "$MANIFEST" ]]; then
  while IFS=$'\t' read -r mode source target; do
    [[ -n "$source" && -n "$target" ]] || continue
    backup_existing "$target" "$BACKUP_DIR"
    remove_managed_item "$source" "$target" "$mode" "$FORCE"
  done < "$MANIFEST"
else
  note "No install manifest found; file targets will be preserved."
fi

for target in "$CURSOR_HOME/hooks.json" "$HOME/.bashrc"; do backup_existing "$target" "$BACKUP_DIR"; done
if [[ "$DRY_RUN" == true ]]; then
  note "dry-run: remove managed Cursor hook and .bashrc blocks"
else
  python3 "$ROOT/lib/manage.py" remove-hooks --destination "$CURSOR_HOME/hooks.json" --template "$ROOT/cursor/hooks.json" --home "$HOME"
fi
remove_managed_block "$HOME/.bashrc" "local-bin"
remove_managed_block "$HOME/.bashrc" "aliases"
[[ "$DRY_RUN" == true ]] || rm -f -- "$MANIFEST"

latest_backup() {
  local candidate
  for candidate in "$(backup_root)"/*; do
    [[ -f "$candidate/.complete" ]] && printf '%s\n' "$candidate"
  done | sort | tail -n 1
}

restore_backup() {
  local backup="$1" source target
  [[ -n "$backup" ]] || { note "No completed backup is available."; return 0; }
  note "Restoring backup: $backup"
  while IFS= read -r source; do
    target="/${source#"$backup/"}"
    if [[ -e "$target" || -L "$target" ]] && [[ "$FORCE" != true ]]; then
      note "preserving existing target during restore: $target (use --force to replace)"
      continue
    fi
    ensure_dir "$(dirname -- "$target")"
    if [[ "$DRY_RUN" == true ]]; then
      note "dry-run: restore $target"
    else
      cp -a -- "$source" "$target"
    fi
  done < <(rg --files "$backup" -g '!.complete')
}

if [[ "$RESTORE" == false && -t 0 ]]; then
  read -r -p "Restore the most recent completed backup? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] && RESTORE=true
fi
if [[ "$RESTORE" == true ]]; then restore_backup "$(latest_backup)"; fi

if [[ "$DRY_RUN" == false ]]; then
  mkdir -p -- "$BACKUP_DIR"
  chmod 700 "$BACKUP_DIR"
  : > "$BACKUP_DIR/.complete"
fi
note "Uninstall complete. Cursor and Codex official binaries were not changed."
