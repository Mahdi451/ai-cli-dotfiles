#!/usr/bin/env bash
# Shared helpers. This file is sourced by repository scripts.

repo_root() {
  cd -- "$(dirname -- "${BASH_SOURCE[1]}")/.." && pwd -P
}

state_root() { printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/ai-cli-dotfiles"; }
config_root() { printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles"; }
backup_root() { printf '%s/backups\n' "$(state_root)"; }
manifest_path() { printf '%s/install-manifest.tsv\n' "$(state_root)"; }

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
note() { printf '%s\n' "$*"; }

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

timestamp() { date -u +%Y%m%d-%H%M%S-%N; }

run() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    printf 'dry-run:'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

ensure_dir() { run mkdir -p "$1"; }

backup_path() {
  local target="$1" backup_dir="$2"
  printf '%s%s\n' "$backup_dir" "$target"
}

backup_existing() {
  local target="$1" backup_dir="$2" backup
  [[ -e "$target" || -L "$target" ]] || return 0
  backup="$(backup_path "$target" "$backup_dir")"
  ensure_dir "$(dirname "$backup")"
  run cp -a -- "$target" "$backup"
}

same_file_or_link() {
  local target="$1" source="$2"
  if [[ -L "$target" ]]; then
    [[ "$(readlink -f -- "$target" 2>/dev/null || true)" == "$(readlink -f -- "$source" 2>/dev/null || true)" ]]
  elif [[ -f "$target" && -f "$source" ]]; then
    cmp -s -- "$target" "$source"
  else
    return 1
  fi
}

install_item() {
  local source="$1" target="$2" mode="$3" backup_dir="$4" force="$5"
  [[ -f "$source" ]] || die "managed source missing: $source"
  ensure_dir "$(dirname "$target")"
  if [[ -e "$target" || -L "$target" ]]; then
    if [[ "$mode" == symlink && -L "$target" ]] && same_file_or_link "$target" "$source"; then
      return 0
    fi
    if [[ "$mode" == copy && ! -L "$target" ]] && same_file_or_link "$target" "$source"; then
      return 0
    fi
    [[ "$force" == true ]] || die "refusing to replace existing unmanaged target: $target (use --force)"
    note "Replacing existing target after backup: $target"
    backup_existing "$target" "$backup_dir"
    run rm -f -- "$target"
  fi
  if [[ "$mode" == symlink ]]; then
    run ln -s -- "$source" "$target"
  else
    run cp -- "$source" "$target"
    run chmod -- "$(stat -c '%a' "$source")" "$target"
  fi
}

remove_managed_item() {
  local source="$1" target="$2" mode="$3" force="$4"
  [[ -e "$target" || -L "$target" ]] || return 0
  if [[ "$mode" == symlink ]]; then
    if [[ -L "$target" ]] && [[ "$(readlink -f -- "$target" 2>/dev/null || true)" == "$(readlink -f -- "$source" 2>/dev/null || true)" ]]; then
      run rm -f -- "$target"
    elif [[ "$force" == true ]]; then
      run rm -f -- "$target"
    else
      note "preserving changed or unmanaged target: $target"
    fi
  elif [[ -f "$target" ]] && cmp -s -- "$source" "$target"; then
    run rm -f -- "$target"
  elif [[ "$force" == true ]]; then
    run rm -f -- "$target"
  else
    note "preserving changed or unmanaged target: $target"
  fi
}

replace_managed_block() {
  local file="$1" name="$2" content="$3" temporary
  if [[ ! -f "$file" ]]; then
    if [[ "${DRY_RUN:-false}" == true ]]; then
      note "dry-run: create $file"
      return 0
    fi
    : > "$file"
  fi
  local begin="# BEGIN AI-CLI-DOTFILES ${name}"
  local end="# END AI-CLI-DOTFILES ${name}"
  local begin_count end_count
  begin_count="$(rg -Fxc "$begin" "$file" || printf '0')"
  end_count="$(rg -Fxc "$end" "$file" || printf '0')"
  [[ "$begin_count" == 0 && "$end_count" == 0 || "$begin_count" == 1 && "$end_count" == 1 ]] || die "malformed or duplicate managed block in $file"
  temporary="$(mktemp)"
  python3 - "$file" "$temporary" "$begin" "$end" "$content" <<'PY'
import sys
source, destination, begin, end, content = sys.argv[1:]
text = open(source, encoding="utf-8").read()
if begin in text:
    start, rest = text.split(begin, 1)
    _, tail = rest.split(end, 1)
    text = start.rstrip("\n") + "\n" + tail.lstrip("\n")
block = f"{begin}\n{content}\n{end}\n"
if text and not text.endswith("\n"):
    text += "\n"
open(destination, "w", encoding="utf-8").write(text + block)
PY
  run cp -- "$temporary" "$file"
  rm -f -- "$temporary"
}

remove_managed_block() {
  local file="$1" name="$2" temporary
  [[ -f "$file" ]] || return 0
  local begin="# BEGIN AI-CLI-DOTFILES ${name}"
  local end="# END AI-CLI-DOTFILES ${name}"
  local begin_count end_count
  begin_count="$(rg -Fxc "$begin" "$file" || printf '0')"
  end_count="$(rg -Fxc "$end" "$file" || printf '0')"
  [[ "$begin_count" == 0 && "$end_count" == 0 ]] && return 0
  [[ "$begin_count" == 1 && "$end_count" == 1 ]] || die "malformed or duplicate managed block in $file"
  temporary="$(mktemp)"
  python3 - "$file" "$temporary" "$begin" "$end" <<'PY'
import sys
source, destination, begin, end = sys.argv[1:]
text = open(source, encoding="utf-8").read()
start, rest = text.split(begin, 1)
_, tail = rest.split(end, 1)
open(destination, "w", encoding="utf-8").write((start.rstrip("\n") + "\n" + tail.lstrip("\n")).rstrip("\n") + "\n")
PY
  run cp -- "$temporary" "$file"
  rm -f -- "$temporary"
}
