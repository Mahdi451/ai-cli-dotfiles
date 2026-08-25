#!/usr/bin/env bash
set -euo pipefail
INCLUDE_CODEX=false
while (($#)); do case "$1" in --include-codex) INCLUDE_CODEX=true;; -h|--help) printf '%s\n' 'Usage: ./backup-current.sh [--include-codex]'; exit 0;; *) printf 'Unknown option: %s\n' "$1" >&2; exit 2;; esac; shift; done
ROOT="$(cd -- "$(dirname -- "$0")" && pwd -P)"
CURSOR_HOME="${CURSOR_HOME:-$HOME/.cursor}" CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
STAGING="$(mktemp -d)"; trap 'rm -rf -- "$STAGING"' EXIT
copy() { [[ -f "$1" ]] || { printf 'Missing required portable source: %s\n' "$1" >&2; exit 1; }; mkdir -p "$STAGING/$(dirname "$2")"; cp -- "$1" "$STAGING/$2"; }
for n in sol-planner.md luna-worker.md terra-implementer.md terra-reviewer.md composer-owner.md grok-advisor.md grok-architect.md grok-reviewer.md grok-escalation.md; do copy "$CURSOR_HOME/agents/$n" "cursor/agents/$n"; done
for n in core.mdc execution-safety.mdc one-line-commands.mdc token-efficiency.mdc git-filesystem-safety.mdc minimal-diff.mdc model-routing.mdc groky-routing-template.mdc verification-before-done.mdc; do copy "$CURSOR_HOME/rules/$n" "cursor/rules/$n"; done
copy "$CURSOR_HOME/hooks/cursor-st-command-guard.py" cursor/hooks/cursor-st-command-guard.py
copy "$CURSOR_HOME/statusline.py" cursor/statusline.py
copy "$HOME/.local/bin/cursor-st" bin/cursor-st
copy "${XDG_CONFIG_HOME:-$HOME/.config}/ai-cli-dotfiles/ai-cli-aliases.sh" shell/ai-cli-aliases.sh
python3 - "$CURSOR_HOME/cli-config.json" "$STAGING/cursor/cli-config.json" <<'PY'
import json, sys
src, dst = sys.argv[1:]
data=json.load(open(src))
allowed=('version','permissions','editor','display','notifications','hints','modelSlashCommands','rewind','exploreSubagentModel','autoAcceptWebSearch','network','attribution','statusLine','model','selectedModel','approvalMode','sandbox')
out={k:data[k] for k in allowed if k in data}
if 'statusLine' in out and isinstance(out['statusLine'],dict):
    out['statusLine']['command']='python3 __CURSOR_HOME__/statusline.py'
model = data.get('model')
if isinstance(model, dict) and isinstance(model.get('modelId'), str):
    out['model'] = {'modelId': model['modelId']}
else:
    out.pop('model', None)
selected = data.get('selectedModel')
if isinstance(selected, dict) and isinstance(selected.get('modelId'), str):
    cleaned = {'modelId': selected['modelId']}
    parameters=[]
    for parameter in selected.get('parameters', []):
        if not isinstance(parameter, dict):
            continue
        pid, value = parameter.get('id'), parameter.get('value')
        if pid == 'reasoning' and isinstance(value, str):
            parameters.append({'id': 'reasoning', 'value': value})
        elif pid == 'fast' and (isinstance(value, str) or isinstance(value, bool)):
            parameters.append({'id': 'fast', 'value': value})
    if not any(p.get('id') == 'fast' for p in parameters):
        parameters.append({'id': 'fast', 'value': 'false'})
    cleaned['parameters'] = parameters
    out['selectedModel'] = cleaned
else:
    out.pop('selectedModel', None)
json.dump(out,open(dst,'w'),indent=2); open(dst,'a').write('\n')
PY
if [[ "$INCLUDE_CODEX" == true ]]; then
  copy "$CODEX_HOME/AGENTS.md" codex/AGENTS.md
  [[ -f "$CODEX_HOME/rules/default.rules" ]] && copy "$CODEX_HOME/rules/default.rules" codex/rules/default.rules
  copy "$HOME/.local/bin/codex-st" bin/codex-st
  copy "$CODEX_HOME/sol-terra-luna.config.toml" codex/config/sol-terra-luna.config.toml
  for n in sol-planner.toml sol-architect.toml sol-reviewer.toml luna-worker.toml terra-implementer.toml terra-reviewer.toml; do copy "$CODEX_HOME/agents/$n" "codex/agents/$n"; done
  python3 "$ROOT/lib/manage.py" sanitize-codex-config --source "$CODEX_HOME/config.toml" --destination "$STAGING/codex/config/config.toml"
fi
python3 "$ROOT/lib/manage.py" scan "$STAGING"
while IFS= read -r f; do rel="${f#"$STAGING/"}"; mkdir -p "$ROOT/$(dirname "$rel")"; cp -- "$f" "$ROOT/$rel"; done < <(rg --files "$STAGING")
printf '%s\n' 'Portable assets captured into the working tree; review the diff before committing.'
