#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
source "$ROOT/lib/common.sh"
REPO_ONLY=false; [[ "${1:-}" == --repo-only ]] && REPO_ONLY=true
failures=0
check() { local label="$1"; shift; if "$@"; then note "ok: $label"; else note "FAIL: $label"; failures=$((failures+1)); fi; }
check "install syntax" bash -n "$ROOT/install.sh"
check "uninstall syntax" bash -n "$ROOT/uninstall.sh"
check "backup syntax" bash -n "$ROOT/backup-current.sh"
check "update syntax" bash -n "$ROOT/update-repo.sh"
check "doctor syntax" bash -n "$ROOT/doctor.sh"
check "smoke-test syntax" bash -n "$ROOT/tests/smoke-test.sh"
check "Cursor wrapper syntax" bash -n "$ROOT/bin/cursor-st"
check "Codex wrapper syntax" bash -n "$ROOT/bin/codex-st"
check "aliases syntax" bash -n "$ROOT/shell/ai-cli-aliases.sh"
check "Cursor JSON" python3 "$ROOT/lib/manage.py" json-validate "$ROOT/cursor/hooks.json"
check "Cursor preferences JSON" python3 "$ROOT/lib/manage.py" json-validate "$ROOT/cursor/cli-config.json"
for f in "$ROOT"/codex/config/*.toml "$ROOT"/codex/agents/*.toml; do check "TOML $(basename "$f")" python3 "$ROOT/lib/manage.py" toml-validate "$f"; done
cache="$(mktemp -d)"; trap 'rm -rf -- "$cache"' EXIT
check "Python compile" env PYTHONPYCACHEPREFIX="$cache" python3 -m py_compile "$ROOT/lib/manage.py" "$ROOT/lib/state.py" "$ROOT/cursor/statusline.py" "$ROOT/cursor/hooks/cursor-st-command-guard.py" "$ROOT/cursor/hooks/prompt-timing.py"
check "repository scanner" python3 "$ROOT/lib/manage.py" scan "$ROOT"
if [[ "$REPO_ONLY" == false ]]; then
  manifest="$(manifest_path)" registry="$(source_registry_path)"
  if [[ ! -e "$manifest" && ! -L "$manifest" && ! -e "$registry" && ! -L "$registry" ]]; then
    note "not installed: no valid managed install metadata for this checkout"
  elif ! records="$(state_command manifest 2>&1)"; then
    note "FAIL: present install metadata is invalid: $records"; failures=$((failures+1))
  else
    note "installed metadata: valid"
    while IFS=$'\t' read -r mode root asset target source; do
      case "$asset" in cursor/hooks.json|cursor/cli-config.json) continue;; esac
      same_file_or_link "$target" "$source" || { note "FAIL: installed asset differs: $target"; failures=$((failures+1)); }
    done <<< "$records"
    CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
    check "installed Cursor hooks" python3 "$ROOT/lib/manage.py" validate-hooks --destination "$CURSOR_HOME/hooks.json" --template "$ROOT/cursor/hooks.json" --cursor-home "$CURSOR_HOME"
    check "installed Cursor preferences" python3 "$ROOT/lib/manage.py" validate-cursor-config --destination "$CURSOR_HOME/cli-config.json" --template "$ROOT/cursor/cli-config.json" --cursor-home "$CURSOR_HOME"
  fi
fi
note "doctor: failures=$failures"
exit "$failures"
