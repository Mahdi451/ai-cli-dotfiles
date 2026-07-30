#!/usr/bin/env bash
set -euo pipefail

REPO_ONLY=false
[[ "${1:-}" != --repo-only ]] || REPO_ONLY=true
[[ "${1:-}" != -h && "${1:-}" != --help ]] || { printf 'Usage: ./doctor.sh [--repo-only]\n'; exit 0; }

ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
# shellcheck source=lib/common.sh
source "$ROOT/lib/common.sh"
failures=0
warnings=0
check() {
  local description="$1"
  shift
  if "$@"; then note "ok: $description"; else note "FAIL: $description"; failures=$((failures + 1)); fi
}
warn() { note "WARN: $*"; warnings=$((warnings + 1)); }

check "repository root" test -d "$ROOT"
check "Python available" python3 -V
check "ripgrep available" rg --version
check "GNU stat available" stat -c '%a' "$ROOT/install.sh"
check "install.sh syntax" bash -n "$ROOT/install.sh"
check "uninstall.sh syntax" bash -n "$ROOT/uninstall.sh"
check "backup-current.sh syntax" bash -n "$ROOT/backup-current.sh"
check "update-repo.sh syntax" bash -n "$ROOT/update-repo.sh"
check "doctor.sh syntax" bash -n "$ROOT/doctor.sh"
check "cursor-st syntax" bash -n "$ROOT/bin/cursor-st"
check "aliases syntax" bash -n "$ROOT/shell/ai-cli-aliases.sh"
check "hook template JSON" python3 "$ROOT/lib/manage.py" json-validate "$ROOT/cursor/hooks.json"
check "repository secret scan" python3 "$ROOT/lib/manage.py" scan "$ROOT"

if [[ "$REPO_ONLY" == false ]]; then
  cursor_home="${CURSOR_HOME:-$HOME/.cursor}"
  if command -v agent >/dev/null 2>&1; then
    agent_path="$(command -v agent)"
    [[ "$(basename -- "$agent_path")" == agent ]] || { note "FAIL: agent does not resolve to official executable"; failures=$((failures + 1)); }
    note "ok: agent -> $agent_path"
  else
    note "FAIL: agent is unavailable"; failures=$((failures + 1))
  fi
  if [[ -x "$HOME/.local/bin/cursor-st" || -L "$HOME/.local/bin/cursor-st" ]]; then
    note "ok: cursor-st target is present"
  else
    warn "cursor-st is not installed"
  fi
  if [[ -f "$HOME/.config/ai-cli-dotfiles/ai-cli-aliases.sh" || -L "$HOME/.config/ai-cli-dotfiles/ai-cli-aliases.sh" ]]; then
    if rg -Fq "alias cyolo='cursor-st --yolo'" "$HOME/.config/ai-cli-dotfiles/ai-cli-aliases.sh"; then note "ok: cyolo maps to cursor-st --yolo"; else note "FAIL: cyolo alias missing"; failures=$((failures + 1)); fi
  else
    warn "aliases are not installed"
  fi
  for kind in agents rules; do
    for source in "$ROOT/cursor/$kind/"*; do
      target="$cursor_home/$kind/$(basename -- "$source")"
      if [[ -L "$target" ]]; then
        [[ "$(readlink -f -- "$target")" == "$(readlink -f -- "$source")" ]] || { note "FAIL: invalid managed symlink: $target"; failures=$((failures + 1)); }
      elif [[ -f "$target" ]]; then
        cmp -s -- "$source" "$target" || warn "installed copy differs from repository: $target"
      else
        warn "missing installed Cursor file: $target"
      fi
    done
  done
  [[ -f "$cursor_home/hooks.json" ]] && check "installed hook JSON" python3 "$ROOT/lib/manage.py" json-validate "$cursor_home/hooks.json"
  for block in local-bin aliases; do
    count="$(rg -Fxc "# BEGIN AI-CLI-DOTFILES $block" "$HOME/.bashrc" 2>/dev/null || true)"
    [[ "$count" == 1 ]] || { note "FAIL: .bashrc $block block count is $count"; failures=$((failures + 1)); }
  done
  if command -v codex >/dev/null 2>&1; then note "ok: Codex CLI is installed"; else warn "Codex CLI is not installed"; fi
fi

git -C "$ROOT" status --short
if command -v agent >/dev/null 2>&1; then
  if command -v timeout >/dev/null 2>&1; then
    models="$(timeout 20 agent --list-models 2>/dev/null || true)"
  else
    models="$(agent --list-models 2>/dev/null || true)"
  fi
  if [[ -n "$models" ]]; then
    for model in gpt-5.6-sol-high gpt-5.6-terra-medium gpt-5.6-terra-high gpt-5.6-luna-medium; do
      [[ "$models" == *"$model"* ]] || warn "Cursor models do not list required model $model"
    done
  else
    warn "Cursor model catalog was unavailable; model pins were verified from local configuration only"
  fi
fi
note "doctor: failures=$failures warnings=$warnings"
exit "$failures"
