#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
TEMP_HOME="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_HOME"' EXIT
mkdir -p "$TEMP_HOME/fake-bin" "$TEMP_HOME/.cursor"
cat > "$TEMP_HOME/fake-bin/agent" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == models ]]; then
  printf '%s\n' gpt-5.6-sol-max gpt-5.6-terra-medium gpt-5.6-luna-low
  exit 0
fi
printf 'ARGS:'
printf ' <%s>' "$@"
printf '\n'
EOF
chmod +x "$TEMP_HOME/fake-bin/agent"
: > "$TEMP_HOME/.bashrc"
printf '%s\n' '{"version":1,"hooks":{"afterFileEdit":[{"command":"keep-me"}]}}' > "$TEMP_HOME/.cursor/hooks.json"

HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" XDG_STATE_HOME="$TEMP_HOME/.state" PATH="$TEMP_HOME/fake-bin:$PATH" "$ROOT/install.sh"
[[ -L "$TEMP_HOME/.local/bin/cursor-st" ]]
[[ "$(readlink -f "$TEMP_HOME/.local/bin/cursor-st")" == "$ROOT/bin/cursor-st" ]]
[[ -L "$TEMP_HOME/.cursor/hooks/cursor-st-command-guard.py" ]]
[[ -L "$TEMP_HOME/.cursor/agents/sol-planner.md" ]]
[[ -L "$TEMP_HOME/.cursor/agents/luna-worker.md" ]]
[[ -L "$TEMP_HOME/.cursor/agents/terra-implementer.md" ]]
[[ -L "$TEMP_HOME/.cursor/agents/terra-reviewer.md" ]]
[[ -L "$TEMP_HOME/.cursor/rules/model-routing.mdc" ]]
rg -Fq 'PARENT_MODEL="${CURSOR_LUNA_MODEL:-gpt-5.6-luna-medium}"' "$TEMP_HOME/.local/bin/cursor-st"
launch_output="$(cd "$TEMP_HOME" && HOME="$TEMP_HOME" PATH="$TEMP_HOME/fake-bin:$PATH" "$TEMP_HOME/.local/bin/cursor-st" --yolo -p test)"
[[ "$launch_output" == *'<--model> <gpt-5.6-luna-medium> <--yolo> <-p> <test>'* ]]
for dangerous in 'git -C repo reset --hard' '/usr/bin/git clean -df' 'rm -fr /'; do
  result="$(printf '{"command":"%s"}' "$dangerous" | python3 "$ROOT/cursor/hooks/cursor-st-command-guard.py")"
  [[ "$result" == *'"permission": "deny"'* ]]
done
python3 - "$TEMP_HOME/.cursor/hooks.json" <<'PY'
import json, sys
hooks = json.load(open(sys.argv[1]))["hooks"]
assert hooks["afterFileEdit"] == [{"command": "keep-me"}]
assert any("cursor-st-command-guard.py" in item["command"] for item in hooks["beforeShellExecution"])
PY
HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" XDG_STATE_HOME="$TEMP_HOME/.state" PATH="$TEMP_HOME/fake-bin:$PATH" "$ROOT/install.sh"
[[ "$(rg -Fxc '# BEGIN AI-CLI-DOTFILES aliases' "$TEMP_HOME/.bashrc")" == 1 ]]
[[ "$(rg -Fxc '# BEGIN AI-CLI-DOTFILES local-bin' "$TEMP_HOME/.bashrc")" == 1 ]]
HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" XDG_STATE_HOME="$TEMP_HOME/.state" PATH="$TEMP_HOME/fake-bin:$PATH" "$ROOT/install.sh" --copy --force
[[ ! -L "$TEMP_HOME/.local/bin/cursor-st" ]]
rg -Fq $'copy\t'"$ROOT/bin/cursor-st"$'\t'"$TEMP_HOME/.local/bin/cursor-st" "$TEMP_HOME/.state/ai-cli-dotfiles/install-manifest.tsv"
HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" XDG_STATE_HOME="$TEMP_HOME/.state" PATH="$TEMP_HOME/fake-bin:$PATH" "$ROOT/install.sh" --include-codex --force
HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" XDG_STATE_HOME="$TEMP_HOME/.state" PATH="$TEMP_HOME/fake-bin:$PATH" "$ROOT/install.sh" --force
rg -Fq "$ROOT/codex/AGENTS.md" "$TEMP_HOME/.state/ai-cli-dotfiles/install-manifest.tsv"
HOME="$TEMP_HOME" XDG_CONFIG_HOME="$TEMP_HOME/.config" XDG_STATE_HOME="$TEMP_HOME/.state" PATH="$TEMP_HOME/fake-bin:$PATH" "$ROOT/uninstall.sh" --dry-run
[[ -f "$TEMP_HOME/.local/bin/cursor-st" ]]

DRY_HOME="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_HOME" "$DRY_HOME"' EXIT
mkdir -p "$DRY_HOME/fake-bin" "$DRY_HOME/.cursor/agents" "$DRY_HOME/.cursor/rules" "$DRY_HOME/.cursor/hooks" "$DRY_HOME/.local/bin"
cp "$TEMP_HOME/fake-bin/agent" "$DRY_HOME/fake-bin/agent"
cp "$ROOT"/cursor/agents/* "$DRY_HOME/.cursor/agents/"
cp "$ROOT"/cursor/rules/* "$DRY_HOME/.cursor/rules/"
cp "$ROOT/cursor/hooks/cursor-st-command-guard.py" "$DRY_HOME/.cursor/hooks/"
cp "$ROOT/bin/cursor-st" "$DRY_HOME/.local/bin/"
HOME="$DRY_HOME" XDG_CONFIG_HOME="$DRY_HOME/.config" XDG_STATE_HOME="$DRY_HOME/.state" PATH="$DRY_HOME/fake-bin:$PATH" "$ROOT/install.sh" --dry-run --force
[[ ! -e "$DRY_HOME/.bashrc" ]]

CONFLICT_HOME="$(mktemp -d)"
trap 'rm -rf -- "$TEMP_HOME" "$DRY_HOME" "$CONFLICT_HOME"' EXIT
mkdir -p "$CONFLICT_HOME/fake-bin" "$CONFLICT_HOME/.local/bin"
cp "$TEMP_HOME/fake-bin/agent" "$CONFLICT_HOME/fake-bin/agent"
printf '%s\n' unrelated > "$CONFLICT_HOME/.local/bin/cursor-st"
if HOME="$CONFLICT_HOME" XDG_CONFIG_HOME="$CONFLICT_HOME/.config" XDG_STATE_HOME="$CONFLICT_HOME/.state" PATH="$CONFLICT_HOME/fake-bin:$PATH" "$ROOT/install.sh" >/dev/null 2>&1; then
  printf '%s\n' 'unmanaged target was overwritten without --force' >&2
  exit 1
fi
[[ "$(cat "$CONFLICT_HOME/.local/bin/cursor-st")" == unrelated ]]
printf '%s\n' 'smoke test passed'
