#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")/.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"; trap 'rm -rf -- "$TEST_ROOT"' EXIT
make_home() { local d; d="$(mktemp -d "$TEST_ROOT/home.XXXXXX")"; mkdir -p "$d/fake-bin"; printf '#!/bin/sh\nexit 0\n' > "$d/fake-bin/agent"; printf '#!/bin/sh\n[ "$1" = "--version" ] && exit 0\nexit 0\n' > "$d/fake-bin/codex"; chmod +x "$d/fake-bin/"*; : > "$d/.bashrc"; printf '%s\n' "$d"; }
run() { local home="$1"; shift; HOME="$home" XDG_CONFIG_HOME="$home/config" XDG_STATE_HOME="$home/state" PATH="$home/fake-bin:$PATH" "$@"; }
first="$(make_home)"
if run "$first" "$ROOT/install.sh" --unknown >/dev/null 2>&1; then exit 1; fi
if run "$first" "$ROOT/install.sh" --cursor-only --codex-only >/dev/null 2>&1; then exit 1; fi
if run "$first" "$ROOT/install.sh" --codex-only --full-access >/dev/null 2>&1; then exit 1; fi
mkdir -p "$first/.cursor"
printf '%s\n' '{"authInfo":{"token":"runtime-only"},"modelSelectionHistory":["old"],"unknownRuntime":true}' > "$first/.cursor/cli-config.json"
run "$first" "$ROOT/install.sh" --copy
[[ -f "$first/.cursor/cli-config.json" && -f "$first/.codex/config.toml" ]]
[[ -f "$first/.cursor/agents/composer-owner.md" && -f "$first/.cursor/agents/grok-reviewer.md" && -f "$first/.cursor/agents/grok-escalation.md" ]]
[[ ! -e "$first/.cursor/agents/grok-advisor.md" && ! -e "$first/.cursor/agents/grok-architect.md" ]]
printf '%s\n' leftover-retired-agent > "$first/.cursor/agents/grok-advisor.md"
printf '%s\n' leftover-retired-agent > "$first/.cursor/agents/grok-architect.md"
run "$first" "$ROOT/install.sh" --copy
[[ ! -e "$first/.cursor/agents/grok-advisor.md" && ! -e "$first/.cursor/agents/grok-architect.md" ]]
python3 - "$first/.cursor/hooks.json" "$first" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); command=x['hooks']['beforeShellExecution'][0]['command']
assert sys.argv[2] + '/.cursor/hooks/cursor-st-command-guard.py' in command and '__' not in command
PY
python3 - "$first/.cursor/cli-config.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['model']['modelId']=='gpt-5.6-sol'; assert any(p.get('id')=='fast' and str(p.get('value')).lower()=='false' for p in x['selectedModel']['parameters']); assert 'approvalMode' not in x; assert x['authInfo']['token']=='runtime-only'; assert x['modelSelectionHistory']==['old']; assert x['unknownRuntime']
PY
run "$first" "$ROOT/doctor.sh"
python3 - "$first/.cursor/cli-config.json" <<'PY'
import json,sys
p=sys.argv[1]; x=json.load(open(p)); x["model"].update({"displayName":"runtime","aliases":["catalog"],"maxMode":False}); x["selectedModel"]["parameters"] += [{"id":"context","value":"1m"}]; json.dump(x,open(p,"w"))
PY
run "$first" "$ROOT/doctor.sh"
python3 - "$first/.cursor/cli-config.json" <<'PY'
import json,sys
p=sys.argv[1]; x=json.load(open(p)); x["model"]["modelId"]="wrong"; json.dump(x,open(p,"w"))
PY
if run "$first" "$ROOT/doctor.sh" >/dev/null 2>&1; then exit 1; fi
run "$first" "$ROOT/install.sh" --copy --force
python3 - "$first/.cursor/cli-config.json" <<'PY'
import json,sys
p=sys.argv[1]; x=json.load(open(p)); x["selectedModel"]["parameters"][0]["value"]="low"; json.dump(x,open(p,"w"))
PY
if run "$first" "$ROOT/doctor.sh" >/dev/null 2>&1; then exit 1; fi
python3 - "$first/.cursor/cli-config.json" <<'PY'
import json,sys
p=sys.argv[1]; x=json.load(open(p)); x["model"]="malformed"; x["selectedModel"]["parameters"]="malformed"; json.dump(x,open(p,"w"))
PY
malformed_doctor_output="$TEST_ROOT/malformed-doctor.out"
if run "$first" "$ROOT/doctor.sh" >"$malformed_doctor_output" 2>&1; then exit 1; fi
! rg -Fq Traceback "$malformed_doctor_output"
status_line_home="$(make_home)"; run "$status_line_home" "$ROOT/install.sh" --copy
python3 - "$status_line_home/.cursor/cli-config.json" <<'PY'
import json,sys
p=sys.argv[1]; x=json.load(open(p)); x["statusLine"]="malformed"; json.dump(x,open(p,"w"))
PY
malformed_status_output="$TEST_ROOT/malformed-status.out"
if run "$status_line_home" "$ROOT/doctor.sh" >"$malformed_status_output" 2>&1; then exit 1; fi
! rg -Fq Traceback "$malformed_status_output"
second="$(make_home)"
mkdir -p "$second/.codex"
printf 'model = "personal"\n' > "$second/.codex/config.toml"
run "$second" "$ROOT/install.sh" --copy
grep -Fqx 'model = "personal"' "$second/.codex/config.toml"
run "$second" "$ROOT/install.sh" --copy --force
grep -Fqx 'model = "personal"' "$second/.codex/config.toml"
run "$second" "$ROOT/install.sh" --copy --replace-config --force
grep -Fqx 'model = "gpt-5.6-sol"' "$second/.codex/config.toml"
third="$(make_home)"
run "$third" "$ROOT/install.sh" --symlink --full-access
[[ -L "$third/.local/bin/cursor-st" && -L "$third/.codex/agents/sol-planner.toml" ]]
run "$third" "$third/.local/bin/cursor-st" --groky --show-flow > "$TEST_ROOT/groky-flow.txt"
rg -Fq "Grok High parent:" "$TEST_ROOT/groky-flow.txt"
rg -Fq "grok-4.6[effort=high,fast=false]" "$TEST_ROOT/groky-flow.txt"
! rg -Fq "Grok advisor:" "$TEST_ROOT/groky-flow.txt"
run "$third" "$third/.local/bin/cursor-st" --groky --doctor >/dev/null
groky_repo="$(mktemp -d "$TEST_ROOT/groky-repo.XXXXXX")"
git -C "$groky_repo" init -q
mkdir -p "$groky_repo/.cursor/rules"
cat > "$groky_repo/.cursor/rules/global-groky-routing.mdc" <<'EOF'
---
alwaysApply: true
---

# Composer 2.5 + Grok 4.6 Routing Template

This rule is a dormant template in the user rules directory. `cursor-st --groky` renders a project-local copy with `alwaysApply: true`. Do not apply this template in ordinary `cursor-st` sessions.
EOF
run "$third" env --chdir="$groky_repo" "$third/.local/bin/cursor-st" --groky --setup-only >/dev/null
rg -Fq "Grok 4.6 High is the parent" "$groky_repo/.cursor/rules/global-groky-routing.mdc"
printf '%s\n' unrelated-project-rule > "$groky_repo/.cursor/rules/global-groky-routing.mdc"
if run "$third" env --chdir="$groky_repo" "$third/.local/bin/cursor-st" --groky --setup-only >/dev/null 2>&1; then exit 1; fi
cat > "$groky_repo/.cursor/rules/global-groky-routing.mdc" <<'EOF'
---
alwaysApply: true
---

# Composer 2.5 + Grok 4.6 Routing Template

This rule is a dormant template in the user rules directory. `cursor-st --groky` renders a project-local copy with `alwaysApply: true`. Do not apply this template in ordinary `cursor-st` sessions.
EOF
run "$third" env --chdir="$groky_repo" "$third/.local/bin/cursor-st" --setup-only >/dev/null
[[ ! -e "$groky_repo/.cursor/rules/global-groky-routing.mdc" ]]
python3 - "$third/.cursor/cli-config.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1])); assert x['approvalMode']=='unrestricted'; assert x['sandbox']['mode']=='disabled'
PY
python3 - "$third/.cursor/cli-config.json" <<'PY'
import json,sys
path=sys.argv[1]; x=json.load(open(path))
x['model'].update({'displayModelId':'stale-display','displayName':'stale name','displayNameShort':'stale','aliases':['legacy'],'maxMode':False})
x['selectedModel']['parameters']=[{'id':'context','value':'272k'},{'id':'reasoning','value':'high'},{'id':'fast','value':'false'}]
x['modelSelectionHistory']=['old-model']
json.dump(x,open(path,'w'))
PY
scratch="$(mktemp -d "$TEST_ROOT/repo.XXXXXX")"; cp -a "$ROOT/." "$scratch/"
before="$(tar -C "$ROOT" --exclude=.git -cf - . | sha256sum | awk '{print $1}')"
run "$third" "$scratch/backup-current.sh" --include-codex
after="$(tar -C "$ROOT" --exclude=.git -cf - . | sha256sum | awk '{print $1}')"; [[ "$before" == "$after" ]]
python3 - "$scratch/cursor/cli-config.json" <<'PY'
import json,sys
x=json.load(open(sys.argv[1]))
assert x['model'] == {'modelId':'gpt-5.6-sol'}
assert x['selectedModel'] == {'modelId':'gpt-5.6-sol','parameters':[{'id':'reasoning','value':'high'},{'id':'fast','value':'false'}]}
text=open(sys.argv[1]).read()
for forbidden in ('displayModelId','displayName','aliases','maxMode','272k','modelSelectionHistory'):
    assert forbidden not in text
PY
for rule in core execution-safety one-line-commands token-efficiency git-filesystem-safety minimal-diff model-routing verification-before-done; do [[ -f "$ROOT/cursor/rules/$rule.mdc" ]]; done
[[ -f "$ROOT/cursor/agents/composer-owner.md" && -f "$ROOT/shell/ai-cli-aliases.sh" ]]
grep -Fq "exec \"\$(find_agent_bin)\" --model 'grok-4.6[effort=high,fast=false]'" "$ROOT/bin/cursor-st"
grep -Fq "exec \"\$(find_agent_bin)\" --model 'gpt-5.6-sol-high[fast=false]'" "$ROOT/bin/cursor-st"
run "$third" "$ROOT/uninstall.sh" --restore --force
[[ ! -e "$third/.local/bin/cursor-st" ]]
fourth="$(make_home)"
run "$fourth" "$ROOT/install.sh" --copy
printf '# local edit\n' >> "$fourth/.local/bin/cursor-st"
printf '%s\n' '# user edit' >> "$fourth/.bashrc"
run "$fourth" "$ROOT/uninstall.sh"
grep -Fq '# local edit' "$fourth/.local/bin/cursor-st"
grep -Fq '# user edit' "$fourth/.bashrc"
run "$fourth" "$ROOT/uninstall.sh" --force
! rg -Fq '# BEGIN AI-CLI-DOTFILES aliases' "$fourth/.bashrc"
fifth="$(make_home)"
run "$fifth" "$ROOT/install.sh" --copy
mkdir -p "$fifth/live"; cp -a "$ROOT/." "$fifth/live/"
HOME="$fifth" XDG_CONFIG_HOME="$fifth/config" XDG_STATE_HOME="$fifth/state" PATH="$fifth/fake-bin:$PATH" "$fifth/live/doctor.sh" >/dev/null
state="$fifth/state/ai-cli-dotfiles/install-manifest.tsv"
grep -Fq $'\tcursor/agents/sol-planner.md\t' "$state"
run "$fifth" "$ROOT/install.sh" --cursor-only --copy
grep -Fq $'\tcodex/agents/sol-planner.toml\t' "$state"
run "$fifth" "$ROOT/install.sh" --codex-only --copy
grep -Fq $'\tcursor/agents/sol-planner.md\t' "$state"
bad="$fifth/state/ai-cli-dotfiles/install-manifest.tsv"; printf 'bad\n' > "$bad"
if run "$fifth" "$ROOT/doctor.sh" >/dev/null 2>&1; then exit 1; fi
codex_only="$(make_home)"
run "$codex_only" "$ROOT/install.sh" --codex-only --copy
[[ -f "$codex_only/config/ai-cli-dotfiles/ai-cli-aliases.sh" && ! -e "$codex_only/.cursor/agents/sol-planner.md" ]]
env PATH="$codex_only/fake-bin:$codex_only/.local/bin:$PATH" bash --noprofile --norc -c 'shopt -s expand_aliases; source "$1"; alias cdx; alias codexy' bash "$codex_only/.bashrc" | rg -F "alias cdx='codex'"

# A failed install leaves its new backup incomplete; latest keeps the prior completed one.
prior="$(run "$first" python3 "$ROOT/lib/state.py" latest --backup-root "$first/state/ai-cli-dotfiles/backups" --state-root "$first/state/ai-cli-dotfiles" --repo-root "$ROOT" --home "$first" --cursor-home "$first/.cursor" --codex-home "$first/.codex" --config-root "$first/config/ai-cli-dotfiles")"
printf '%s\n' unmanaged > "$first/.local/bin/cursor-st"
if run "$first" "$ROOT/install.sh" --copy >/dev/null 2>&1; then exit 1; fi
latest="$(run "$first" python3 "$ROOT/lib/state.py" latest --backup-root "$first/state/ai-cli-dotfiles/backups" --state-root "$first/state/ai-cli-dotfiles" --repo-root "$ROOT" --home "$first" --cursor-home "$first/.cursor" --codex-home "$first/.codex" --config-root "$first/config/ai-cli-dotfiles")"
[[ "$latest" == "$prior" ]]
newest="$(find "$first/state/ai-cli-dotfiles/backups" -mindepth 1 -maxdepth 1 -type d | sort | tail -n1)"; [[ ! -e "$newest/.complete" ]]
empty="$(make_home)"; mkdir -p "$empty/state/ai-cli-dotfiles/backups"; chmod 700 "$empty/state" "$empty/state/ai-cli-dotfiles" "$empty/state/ai-cli-dotfiles/backups"; [[ -z "$(run "$empty" python3 "$ROOT/lib/state.py" latest --backup-root "$empty/state/ai-cli-dotfiles/backups" --state-root "$empty/state/ai-cli-dotfiles" --repo-root "$ROOT" --home "$empty" --cursor-home "$empty/.cursor" --codex-home "$empty/.codex" --config-root "$empty/config/ai-cli-dotfiles")" ]]

# Retained records survive a moved source checkout: copies use current-root fallback;
# symlinks are verified by their stored raw link target.
old="$(mktemp -d "$TEST_ROOT/old.XXXXXX")"; new="$(mktemp -d "$TEST_ROOT/new.XXXXXX")"; cp -a "$ROOT/." "$old/"; cp -a "$ROOT/." "$new/"
move_home="$(make_home)"; run "$move_home" "$old/install.sh" --copy
HOME="$move_home" XDG_CONFIG_HOME="$move_home/config" XDG_STATE_HOME="$move_home/state" PATH="$move_home/fake-bin:$PATH" "$new/install.sh" --codex-only --copy
mv "$old" "$TEST_ROOT/old-gone"; HOME="$move_home" XDG_CONFIG_HOME="$move_home/config" XDG_STATE_HOME="$move_home/state" PATH="$move_home/fake-bin:$PATH" "$new/uninstall.sh" --force
[[ ! -e "$move_home/.local/bin/cursor-st" ]]
link_home="$(make_home)"; old2="$(mktemp -d "$TEST_ROOT/old2.XXXXXX")"; new2="$(mktemp -d "$TEST_ROOT/new2.XXXXXX")"; cp -a "$ROOT/." "$old2/"; cp -a "$ROOT/." "$new2/"
run "$link_home" "$old2/install.sh" --symlink
HOME="$link_home" XDG_CONFIG_HOME="$link_home/config" XDG_STATE_HOME="$link_home/state" PATH="$link_home/fake-bin:$PATH" "$new2/install.sh" --codex-only --symlink
mv "$old2" "$TEST_ROOT/old2-gone"; HOME="$link_home" XDG_CONFIG_HOME="$link_home/config" XDG_STATE_HOME="$link_home/state" PATH="$link_home/fake-bin:$PATH" "$new2/uninstall.sh" --force
[[ ! -e "$link_home/.local/bin/cursor-st" ]]

# A user edit inside a marked block is preserved until forced removal.
block_home="$(make_home)"; run "$block_home" "$ROOT/install.sh" --copy
sed -i '/# END AI-CLI-DOTFILES aliases/i# inside managed block' "$block_home/.bashrc"
run "$block_home" "$ROOT/uninstall.sh"; rg -Fq '# inside managed block' "$block_home/.bashrc"
run "$block_home" "$ROOT/uninstall.sh" --force; ! rg -Fq '# BEGIN AI-CLI-DOTFILES aliases' "$block_home/.bashrc"

# Publishing must fail closed before backup/smoke/commit when unrelated content is staged.
publish_repo="$(mktemp -d "$TEST_ROOT/publish.XXXXXX")"; tar -C "$ROOT" --exclude=.git -cf - . | tar -C "$publish_repo" -xf -
git -C "$publish_repo" init -q; git -C "$publish_repo" config user.email test@example.invalid; git -C "$publish_repo" config user.name test
git -C "$publish_repo" add -A; git -C "$publish_repo" commit -qm baseline
printf '%s\n' private > "$publish_repo/unrelated.txt"; git -C "$publish_repo" add unrelated.txt
if HOME="$block_home" XDG_CONFIG_HOME="$block_home/config" XDG_STATE_HOME="$block_home/state" PATH="$block_home/fake-bin:$PATH" "$publish_repo/update-repo.sh" --message guarded >/dev/null 2>&1; then exit 1; fi
[[ "$(git -C "$publish_repo" diff --cached --name-only)" == unrelated.txt ]]
git -C "$publish_repo" reset -q
printf '%s\n' rename-me > "$publish_repo/external.txt"; git -C "$publish_repo" add external.txt; git -C "$publish_repo" commit -qm external
git -C "$publish_repo" config diff.renames true
git -C "$publish_repo" mv external.txt bin/renamed-external.txt
before_rename="$(git -C "$publish_repo" diff --cached --no-renames --name-status)"
if HOME="$block_home" XDG_CONFIG_HOME="$block_home/config" XDG_STATE_HOME="$block_home/state" PATH="$block_home/fake-bin:$PATH" "$publish_repo/update-repo.sh" --message guarded-rename >/dev/null 2>&1; then exit 1; fi
[[ "$(git -C "$publish_repo" diff --cached --no-renames --name-status)" == "$before_rename" ]]
python3 "$ROOT/lib/manage.py" toml-validate "$ROOT/codex/config/config.toml"
python3 - "$ROOT/codex/config/config.toml" <<'PY'
import tomllib,sys
x=tomllib.load(open(sys.argv[1],'rb')); assert x['features']['multi_agent']; assert 'terminal_resize_reflow' not in x['features']
PY
cat > "$fifth/unsafe.toml" <<'EOF'
model = "gpt-5.6-sol"
personality = "pragmatic"
[projects."/machine/path"]
trust_level = "trusted"
[notice]
hide_full_access_warning = true
[machine_state]
token = "runtime-token-value-1234567890"
EOF
python3 "$ROOT/lib/manage.py" sanitize-codex-config --source "$fifth/unsafe.toml" --destination "$fifth/safe.toml"
python3 - "$fifth/safe.toml" <<'PY'
import sys,tomllib
t=open(sys.argv[1]).read(); x=tomllib.loads(t); assert 'projects' not in t and 'notice' not in t and 'machine_state' not in t and 'token' not in t; assert x['model']=='gpt-5.6-sol'
PY
echo 'smoke tests: PASS'
