#!/usr/bin/env python3
"""Small dependency-free helpers for ai-cli-dotfiles."""
from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import stat
import sys
import tempfile
from pathlib import Path

FORBIDDEN_NAMES = {
    "auth.json", ".env", ".git-credentials", ".netrc", "hosts.yml",
    "id_rsa", "id_ed25519", "credentials.json",
}
PATTERNS = {
    "private-key": re.compile(r"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----"),
    "github-token": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{30,})\b"),
    "openai-token": re.compile(r"\bsk-(?:proj-)?[A-Za-z0-9_-]{20,}\b"),
    "aws-key": re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    "bearer-token": re.compile(r"(?i)\bbearer\s+[A-Za-z0-9._-]{20,}"),
    "credential-assignment": re.compile(
        r"(?i)^\s*(?:api[_-]?key|access[_-]?token|secret|password)\s*[:=]\s*['\"]?[A-Za-z0-9._/-]{16,}"
    ),
}


def iter_files(paths: list[str]):
    for raw in paths:
        path = Path(raw)
        if path.is_file():
            yield path
        elif path.is_dir():
            for item in path.rglob("*"):
                if item.is_file() and ".git" not in item.parts:
                    yield item


def scan(paths: list[str]) -> int:
    findings: list[tuple[Path, int, str]] = []
    for path in iter_files(paths):
        if path.name in FORBIDDEN_NAMES or path.suffix in {".pem", ".key", ".p12", ".pfx"}:
            findings.append((path, 0, "forbidden-filename"))
            continue
        try:
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            findings.append((path, 0, "unreadable-file"))
            continue
        for number, line in enumerate(lines, start=1):
            for name, pattern in PATTERNS.items():
                if pattern.search(line):
                    findings.append((path, number, name))
                    break
    for path, line, rule in findings:
        suffix = f":{line}" if line else ""
        print(f"secret-scan: {path}{suffix}: {rule}", file=sys.stderr)
    return 1 if findings else 0


def validate_json(path: str) -> int:
    try:
        with open(path, encoding="utf-8") as handle:
            json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"invalid JSON: {path}: {exc}", file=sys.stderr)
        return 1
    return 0


def validate_toml(path: str) -> int:
    try:
        import tomllib
    except ModuleNotFoundError:
        print(
            "TOML validation requires Python 3.11+; install a newer Python "
            "or validate this file with another TOML parser.",
            file=sys.stderr,
        )
        return 1
    try:
        with open(path, "rb") as handle:
            tomllib.load(handle)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        print(f"invalid TOML: {path}: {exc}", file=sys.stderr)
        return 1
    return 0


def render_managed_hooks(template: dict, cursor_home: str) -> dict:
    result = json.loads(json.dumps(template))
    for entries in result.get("hooks", {}).values():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if isinstance(entry, dict) and isinstance(entry.get("command"), str):
                entry["command"] = entry["command"].replace("__CURSOR_HOME__", shlex.quote(cursor_home))
    return result


def load_hook_template(template_path: str, action: str) -> dict | None:
    try:
        template = json.loads(Path(template_path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot {action} hooks: {exc}", file=sys.stderr)
        return None
    if not isinstance(template, dict) or not isinstance(template.get("hooks"), dict):
        print(f"cannot {action} hooks: template must be a JSON object with a hooks object", file=sys.stderr)
        return None
    return template


def atomic_write_json(destination_path: Path, content: dict, action: str) -> int:
    temporary_path: str | None = None
    try:
        destination_path.parent.mkdir(parents=True, exist_ok=True)
        mode = (
            stat.S_IMODE(destination_path.stat().st_mode)
            if destination_path.exists()
            else 0o600
        )
        descriptor, temporary_path = tempfile.mkstemp(
            prefix=f".{destination_path.name}.",
            suffix=".tmp",
            dir=destination_path.parent,
        )
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            os.fchmod(handle.fileno(), mode)
            try:
                json.dump(content, handle, indent=2)
                handle.write("\n")
                handle.flush()
                os.fsync(handle.fileno())
            except BaseException:
                raise
        os.replace(temporary_path, destination_path)
        temporary_path = None
        return 0
    except OSError as exc:
        print(f"cannot {action} hooks: {exc}", file=sys.stderr)
        return 1
    finally:
        if temporary_path is not None:
            try:
                os.unlink(temporary_path)
            except FileNotFoundError:
                pass


def merge_hooks(destination: str, template_path: str, cursor_home: str) -> int:
    destination_path = Path(destination)
    if destination_path.is_symlink():
        print("cannot merge hooks: refusing to replace destination symlink", file=sys.stderr)
        return 1
    try:
        current = json.loads(destination_path.read_text(encoding="utf-8")) if destination_path.exists() else {"version": 1, "hooks": {}}
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot merge hooks: {exc}", file=sys.stderr)
        return 1
    if not isinstance(current, dict) or not isinstance(current.get("hooks", {}), dict):
        print("cannot merge hooks: destination must be a JSON object with a hooks object", file=sys.stderr)
        return 1
    template = load_hook_template(template_path, "merge")
    if template is None:
        return 1
    template = render_managed_hooks(template, cursor_home)
    hooks = current.setdefault("hooks", {})
    hooks.setdefault("beforeShellExecution", [])
    if not isinstance(hooks["beforeShellExecution"], list):
        print("cannot merge hooks: beforeShellExecution must be an array", file=sys.stderr)
        return 1
    for event, entries in template.get("hooks", {}).items():
        if not isinstance(entries, list):
            print(f"cannot merge hooks: template {event} must be an array", file=sys.stderr)
            return 1
        existing = hooks.setdefault(event, [])
        if not isinstance(existing, list):
            print(f"cannot merge hooks: destination {event} must be an array", file=sys.stderr)
            return 1
        for entry in entries:
            existing[:] = [current_entry for current_entry in existing if current_entry != entry]
            existing.append(entry)
    current.setdefault("version", 1)
    return atomic_write_json(destination_path, current, "merge")


def remove_hooks(destination: str, template_path: str, cursor_home: str) -> int:
    destination_path = Path(destination)
    if destination_path.is_symlink():
        print("cannot remove managed hooks: refusing to replace destination symlink", file=sys.stderr)
        return 1
    if not destination_path.exists():
        return 0
    try:
        current = json.loads(destination_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot remove managed hooks: {exc}", file=sys.stderr)
        return 1
    if not isinstance(current, dict) or not isinstance(current.get("hooks", {}), dict):
        print("cannot remove managed hooks: invalid destination", file=sys.stderr)
        return 1
    template = load_hook_template(template_path, "remove managed")
    if template is None:
        return 1
    template = render_managed_hooks(template, cursor_home)
    for event, entries in template.get("hooks", {}).items():
        existing = current["hooks"].get(event)
        if isinstance(existing, list):
            current["hooks"][event] = [entry for entry in existing if entry not in entries]
            if not current["hooks"][event]:
                del current["hooks"][event]
    return atomic_write_json(destination_path, current, "remove managed")


def validate_hooks(destination: str, template_path: str, cursor_home: str) -> int:
    destination_path = Path(destination)
    try:
        current = json.loads(destination_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"invalid managed hooks: {exc}", file=sys.stderr)
        return 1
    if not isinstance(current, dict) or not isinstance(current.get("hooks"), dict):
        print("invalid managed hooks: destination must be a JSON object with a hooks object", file=sys.stderr)
        return 1
    template = load_hook_template(template_path, "validate managed")
    if template is None:
        return 1
    for event, entries in render_managed_hooks(template, cursor_home).get("hooks", {}).items():
        existing = current["hooks"].get(event)
        if not isinstance(entries, list) or not isinstance(existing, list):
            print(f"invalid managed hooks: missing managed event {event}", file=sys.stderr)
            return 1
        for entry in entries:
            if existing.count(entry) != 1:
                print(f"invalid managed hooks: managed entry count in {event} is not exactly one", file=sys.stderr)
                return 1
    return 0


def merge_cursor_config(destination: str, template_path: str, cursor_home: str, full_access: bool) -> int:
    """Merge only documented portable preferences; never import runtime state."""
    path = Path(destination)
    if path.is_symlink():
        print("cannot merge Cursor config: refusing to replace destination symlink", file=sys.stderr)
        return 1
    try:
        current = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
        template = json.loads(Path(template_path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot merge Cursor config: {exc}", file=sys.stderr)
        return 1
    if not isinstance(current, dict) or not isinstance(template, dict):
        print("cannot merge Cursor config: both files must contain objects", file=sys.stderr)
        return 1
    allow = ("version", "permissions", "editor", "display", "notifications", "hints", "modelSlashCommands", "rewind", "exploreSubagentModel", "subagentModels", "autoAcceptWebSearch", "network", "attribution", "statusLine", "model", "selectedModel")
    for key in allow:
        if key in template:
            current[key] = template[key]
    current["statusLine"] = json.loads(json.dumps(current["statusLine"]))
    current["statusLine"]["command"] = current["statusLine"]["command"].replace("__CURSOR_HOME__", shlex.quote(cursor_home))
    if full_access:
        current["approvalMode"] = template["approvalMode"]
        current["sandbox"] = template["sandbox"]
    return atomic_write_json(path, current, "merge Cursor config")


def validate_cursor_config(destination: str, template_path: str, cursor_home: str) -> int:
    try:
        current = json.loads(Path(destination).read_text(encoding="utf-8"))
        template = json.loads(Path(template_path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"invalid managed Cursor config: {exc}", file=sys.stderr)
        return 1
    if not isinstance(current, dict) or not isinstance(template, dict):
        return 1
    for key in ("version", "permissions", "editor", "display", "notifications", "hints", "modelSlashCommands", "rewind", "exploreSubagentModel", "subagentModels", "autoAcceptWebSearch", "network", "attribution"):
        if current.get(key) != template.get(key):
            print(f"invalid managed Cursor config: {key} differs", file=sys.stderr)
            return 1
    model = current.get("model")
    selected = current.get("selectedModel")
    expected_model = template.get("model")
    expected_selected = template.get("selectedModel")
    if not all(isinstance(value, dict) for value in (model, selected, expected_model, expected_selected)):
        print("invalid managed Cursor config: model metadata must be objects", file=sys.stderr)
        return 1
    if model.get("modelId") != expected_model.get("modelId"):
        print("invalid managed Cursor config: modelId differs", file=sys.stderr)
        return 1
    if selected.get("modelId") != expected_selected.get("modelId"):
        print("invalid managed Cursor config: selected modelId differs", file=sys.stderr)
        return 1
    expected_parameters = expected_selected.get("parameters")
    actual_parameters = selected.get("parameters")
    if not isinstance(expected_parameters, list) or not isinstance(actual_parameters, list) or not all(isinstance(item, dict) for item in expected_parameters + actual_parameters):
        print("invalid managed Cursor config: selected parameters must be object arrays", file=sys.stderr)
        return 1
    expected_reasoning = next((p.get("value") for p in expected_parameters if p.get("id") == "reasoning"), None)
    actual_reasoning = next((p.get("value") for p in actual_parameters if p.get("id") == "reasoning"), None)
    if actual_reasoning != expected_reasoning:
        print("invalid managed Cursor config: selected reasoning differs", file=sys.stderr)
        return 1
    for key in ("approvalMode", "sandbox"):
        if key in current and current.get(key) != template.get(key):
            print(f"invalid managed Cursor config: {key} differs", file=sys.stderr)
            return 1
    current_status_line = current.get("statusLine")
    template_status_line = template.get("statusLine")
    if not isinstance(current_status_line, dict) or not isinstance(template_status_line, dict):
        print("invalid managed Cursor config: status line must be an object", file=sys.stderr)
        return 1
    expected = template_status_line.get("command", "").replace("__CURSOR_HOME__", shlex.quote(cursor_home))
    if current_status_line.get("command") != expected:
        print("invalid managed Cursor config: status line differs", file=sys.stderr)
        return 1
    return 0


def sanitize_codex_config(source: str, destination: str) -> int:
    try:
        import tomllib
        data = tomllib.loads(Path(source).read_text(encoding="utf-8"))
    except (OSError, tomllib.TOMLDecodeError) as exc:
        print(f"cannot sanitize Codex config: {exc}", file=sys.stderr)
        return 1
    scalar = ("model", "model_reasoning_effort", "personality", "plan_mode_reasoning_effort", "instructions_file", "approvals_reviewer")
    lines = [f"{key} = {json.dumps(data[key])}" for key in scalar if isinstance(data.get(key), str)]
    for table, keys in (("features", ("unified_exec", "goals", "memories", "prevent_idle_sleep", "multi_agent")), ("agents", ("enabled", "default_subagent_model", "default_subagent_reasoning_effort"))):
        values = data.get(table, {})
        if isinstance(values, dict):
            selected = [(k, values[k]) for k in keys if isinstance(values.get(k), (str, bool))]
            if selected:
                lines.extend(["", f"[{table}]"] + [f"{k} = {json.dumps(v)}" for k, v in selected])
    tui = data.get("tui", {})
    if isinstance(tui, dict):
        selected = [(k, tui[k]) for k in ("status_line", "theme", "status_line_use_colors") if isinstance(tui.get(k), (str, bool, list))]
        if selected:
            lines.extend(["", "[tui]"] + [f"{k} = {json.dumps(v)}" for k, v in selected])
    plugin = data.get("plugins", {}).get("github@openai-curated", {}) if isinstance(data.get("plugins"), dict) else {}
    if isinstance(plugin, dict) and isinstance(plugin.get("enabled"), bool):
        lines.extend(["", '[plugins."github@openai-curated"]', f"enabled = {json.dumps(plugin['enabled'])}"])
    Path(destination).write_text("\n".join(lines).strip() + "\n", encoding="utf-8")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    scan_parser = subparsers.add_parser("scan")
    scan_parser.add_argument("paths", nargs="+")
    json_parser = subparsers.add_parser("json-validate")
    json_parser.add_argument("path")
    toml_parser = subparsers.add_parser("toml-validate")
    toml_parser.add_argument("path")
    for name in ("merge-hooks", "remove-hooks", "validate-hooks"):
        hook_parser = subparsers.add_parser(name)
        hook_parser.add_argument("--destination", required=True)
        hook_parser.add_argument("--template", required=True)
        home_group = hook_parser.add_mutually_exclusive_group(required=True)
        home_group.add_argument("--cursor-home")
        home_group.add_argument("--home", help="legacy alias; renders under HOME/.cursor")
    config_parser = subparsers.add_parser("merge-cursor-config")
    config_parser.add_argument("--destination", required=True)
    config_parser.add_argument("--template", required=True)
    config_parser.add_argument("--cursor-home", required=True)
    config_parser.add_argument("--full-access", action="store_true")
    config_validate = subparsers.add_parser("validate-cursor-config")
    config_validate.add_argument("--destination", required=True)
    config_validate.add_argument("--template", required=True)
    config_validate.add_argument("--cursor-home", required=True)
    sanitize_parser = subparsers.add_parser("sanitize-codex-config")
    sanitize_parser.add_argument("--source", required=True)
    sanitize_parser.add_argument("--destination", required=True)
    args = parser.parse_args()
    if args.command == "scan":
        return scan(args.paths)
    if args.command == "json-validate":
        return validate_json(args.path)
    if args.command == "toml-validate":
        return validate_toml(args.path)
    if args.command == "merge-cursor-config":
        return merge_cursor_config(args.destination, args.template, args.cursor_home, args.full_access)
    if args.command == "validate-cursor-config":
        return validate_cursor_config(args.destination, args.template, args.cursor_home)
    if args.command == "sanitize-codex-config":
        return sanitize_codex_config(args.source, args.destination)
    cursor_home = args.cursor_home or str(Path(args.home) / ".cursor")
    if args.command == "merge-hooks":
        return merge_hooks(args.destination, args.template, cursor_home)
    if args.command == "remove-hooks":
        return remove_hooks(args.destination, args.template, cursor_home)
    return validate_hooks(args.destination, args.template, cursor_home)


if __name__ == "__main__":
    raise SystemExit(main())
