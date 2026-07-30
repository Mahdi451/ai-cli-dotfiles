#!/usr/bin/env bash
set -euo pipefail

INCLUDE_CODEX=false
PUSH=false
while (($#)); do
  case "$1" in
    --include-codex) INCLUDE_CODEX=true ;;
    --push) PUSH=true ;;
    -h|--help) printf 'Usage: ./backup-current.sh [--include-codex] [--push]\n'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}"
STAGING="$(mktemp -d)"
trap 'rm -rf -- "$STAGING"' EXIT

copy_safe() {
  local source="$1" relative="$2" destination="$STAGING/$relative"
  [[ -f "$source" ]] || { printf 'Missing source: %s\n' "$source" >&2; exit 1; }
  mkdir -p -- "$(dirname -- "$destination")"
  cp -- "$source" "$destination"
  chmod -- "$(stat -c '%a' "$source")" "$destination"
}

for name in sol-planner.md luna-worker.md terra-implementer.md terra-reviewer.md; do
  copy_safe "$CURSOR_HOME/agents/$name" "cursor/agents/$name"
done
for name in model-routing.mdc verification-before-done.mdc minimal-diff.mdc git-filesystem-safety.mdc; do
  copy_safe "$CURSOR_HOME/rules/$name" "cursor/rules/$name"
done
copy_safe "$CURSOR_HOME/hooks/cursor-st-command-guard.py" "cursor/hooks/cursor-st-command-guard.py"
copy_safe "$HOME/.local/bin/cursor-st" "bin/cursor-st"
python3 - "$STAGING/bin/cursor-st" "$HOME" <<'PY'
import re
import sys
path, home = sys.argv[1:]
text = open(path, encoding="utf-8").read()
quoted_home = re.compile(r"(['\"])" + re.escape(home) + r"([^'\"]*)\1")
text = quoted_home.sub(lambda match: '"$HOME' + match.group(2) + '"', text)
if home in text:
    raise SystemExit("refusing to capture cursor-st: unsanitized home path remains")
open(path, "w", encoding="utf-8").write(text)
PY

# The portable hook template deliberately contains a placeholder, not the
# machine-specific command string found in the live hooks.json.
mkdir -p -- "$STAGING/cursor"
cp -- "$ROOT/cursor/hooks.json" "$STAGING/cursor/hooks.json"

if [[ "$INCLUDE_CODEX" == true ]]; then
  CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
  [[ -f "$CODEX_HOME/AGENTS.md" ]] && copy_safe "$CODEX_HOME/AGENTS.md" "codex/AGENTS.md"
  [[ -f "$CODEX_HOME/rules/default.rules" ]] && copy_safe "$CODEX_HOME/rules/default.rules" "codex/rules/default.rules"
  # config.toml is intentionally not copied automatically: it can include
  # credentials and machine-local trusted-project settings.
fi

python3 "$ROOT/lib/manage.py" scan "$STAGING"

# Replace only whitelisted captured files after staging passed scanning.
while IFS= read -r source; do
  relative="${source#"$STAGING/"}"
  destination="$ROOT/$relative"
  mkdir -p -- "$(dirname -- "$destination")"
  cp -- "$source" "$destination"
  chmod -- "$(stat -c '%a' "$source")" "$destination"
done < <(rg --files --hidden "$STAGING")

git -C "$ROOT" diff -- . || true
if [[ "$PUSH" == true ]]; then
  managed_paths=(.gitignore LICENSE README.md install.sh uninstall.sh backup-current.sh update-repo.sh doctor.sh bin cursor codex lib shell templates tests)
  git -C "$ROOT" add -- "${managed_paths[@]}"
  staged="$(git -C "$ROOT" diff --cached --name-only)"
  [[ -n "$staged" ]] || { printf '%s\n' 'No changes to commit.'; exit 0; }
  staged_dir="$(mktemp -d)"
  while IFS= read -r path; do
    [[ -n "$path" ]] || continue
    mkdir -p -- "$(dirname -- "$staged_dir/$path")"
    git -C "$ROOT" show ":$path" > "$staged_dir/$path"
  done <<< "$staged"
  python3 "$ROOT/lib/manage.py" scan "$staged_dir"
  rm -rf -- "$staged_dir"
  git -C "$ROOT" commit -m "Backup current AI CLI configuration"
  command -v gh >/dev/null 2>&1 || { printf '%s\n' 'gh is required for --push.' >&2; exit 1; }
  remote="$(git -C "$ROOT" remote get-url --push origin)"
  [[ "$(gh repo view "$remote" --json visibility --jq .visibility)" == PRIVATE ]] || { printf '%s\n' 'Refusing to push to a non-private remote.' >&2; exit 1; }
  git -C "$ROOT" push
fi
printf '%s\n' 'Backup captured into the working tree. Review git diff, then use update-repo.sh to commit.'
