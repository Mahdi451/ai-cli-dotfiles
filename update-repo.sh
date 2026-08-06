#!/usr/bin/env bash
set -euo pipefail

MESSAGE=''
PUSH=false
INCLUDE_CODEX=false
while (($#)); do
  case "$1" in
    --message) [[ $# -ge 2 ]] || { printf '%s\n' '--message requires a value' >&2; exit 2; }; MESSAGE="$2"; shift ;;
    --push) PUSH=true ;;
    --include-codex) INCLUDE_CODEX=true ;;
    -h|--help) printf 'Usage: ./update-repo.sh --message "..." [--include-codex] [--push]\n'; exit 0 ;;
    *) printf 'Unknown option: %s\n' "$1" >&2; exit 2 ;;
  esac
  shift
done
[[ -n "$MESSAGE" ]] || { printf '%s\n' '--message is required' >&2; exit 2; }

ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1 || { printf '%s\n' 'Initialize Git before updating.' >&2; exit 1; }
managed_paths=(.gitignore LICENSE README.md install.sh uninstall.sh backup-current.sh update-repo.sh doctor.sh bin cursor codex lib shell templates tests)
is_managed_path() {
  local path="$1" root
  for root in "${managed_paths[@]}"; do
    [[ "$path" == "$root" || "$path" == "$root/"* ]] && return 0
  done
  return 1
}
while IFS= read -r -d '' staged_path; do
  is_managed_path "$staged_path" || {
    printf 'Refusing to publish: unrelated pre-staged path: %s\n' "$staged_path" >&2
    exit 1
  }
done < <(git -C "$ROOT" diff --cached --no-renames --name-only -z)
args=()
[[ "$INCLUDE_CODEX" == true ]] && args+=(--include-codex)
"$ROOT/backup-current.sh" "${args[@]}"
python3 "$ROOT/lib/manage.py" scan "$ROOT"
bash -n "$ROOT/install.sh" "$ROOT/uninstall.sh" "$ROOT/backup-current.sh" "$ROOT/update-repo.sh" "$ROOT/doctor.sh" "$ROOT/bin/cursor-st" "$ROOT/bin/codex-st" "$ROOT/shell/ai-cli-aliases.sh"
python3 "$ROOT/lib/manage.py" json-validate "$ROOT/cursor/hooks.json"
for config in "$ROOT"/codex/config/*.toml "$ROOT"/codex/agents/*.toml; do python3 "$ROOT/lib/manage.py" toml-validate "$config"; done
"$ROOT/tests/smoke-test.sh"
git -C "$ROOT" diff --check
git -C "$ROOT" diff
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
git -C "$ROOT" commit -m "$MESSAGE"
if [[ "$PUSH" == true ]]; then
  command -v gh >/dev/null 2>&1 || { printf '%s\n' 'gh is required to verify private visibility before push.' >&2; exit 1; }
  remote="$(git -C "$ROOT" remote get-url --push origin)"
  visibility="$(gh repo view "$remote" --json visibility --jq .visibility)"
  [[ "$visibility" == PRIVATE ]] || { printf 'Refusing to push: remote visibility is %s, not PRIVATE.\n' "$visibility" >&2; exit 1; }
  git -C "$ROOT" push
fi
