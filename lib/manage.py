#!/usr/bin/env python3
"""Small dependency-free helpers for ai-cli-dotfiles."""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
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


def managed_commands(template: dict, home: str) -> dict:
    result = json.loads(json.dumps(template))
    for entries in result.get("hooks", {}).values():
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if isinstance(entry, dict) and isinstance(entry.get("command"), str):
                entry["command"] = entry["command"].replace("__HOME__", home)
    return result


def merge_hooks(destination: str, template_path: str, home: str) -> int:
    destination_path = Path(destination)
    try:
        current = json.loads(destination_path.read_text(encoding="utf-8")) if destination_path.exists() else {"version": 1, "hooks": {}}
        template = json.loads(Path(template_path).read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot merge hooks: {exc}", file=sys.stderr)
        return 1
    if not isinstance(current, dict) or not isinstance(current.get("hooks", {}), dict):
        print("cannot merge hooks: destination must be a JSON object with a hooks object", file=sys.stderr)
        return 1
    template = managed_commands(template, home)
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
            if entry not in existing:
                existing.append(entry)
    current.setdefault("version", 1)
    destination_path.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination_path.with_suffix(destination_path.suffix + ".tmp")
    temporary.write_text(json.dumps(current, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, destination_path)
    return 0


def remove_hooks(destination: str, template_path: str, home: str) -> int:
    destination_path = Path(destination)
    if not destination_path.exists():
        return 0
    try:
        current = json.loads(destination_path.read_text(encoding="utf-8"))
        template = managed_commands(json.loads(Path(template_path).read_text(encoding="utf-8")), home)
    except (OSError, json.JSONDecodeError) as exc:
        print(f"cannot remove managed hooks: {exc}", file=sys.stderr)
        return 1
    if not isinstance(current, dict) or not isinstance(current.get("hooks", {}), dict):
        print("cannot remove managed hooks: invalid destination", file=sys.stderr)
        return 1
    for event, entries in template.get("hooks", {}).items():
        existing = current["hooks"].get(event)
        if isinstance(existing, list):
            current["hooks"][event] = [entry for entry in existing if entry not in entries]
            if not current["hooks"][event]:
                del current["hooks"][event]
    temporary = destination_path.with_suffix(destination_path.suffix + ".tmp")
    temporary.write_text(json.dumps(current, indent=2) + "\n", encoding="utf-8")
    os.replace(temporary, destination_path)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    subparsers = parser.add_subparsers(dest="command", required=True)
    scan_parser = subparsers.add_parser("scan")
    scan_parser.add_argument("paths", nargs="+")
    json_parser = subparsers.add_parser("json-validate")
    json_parser.add_argument("path")
    for name in ("merge-hooks", "remove-hooks"):
        hook_parser = subparsers.add_parser(name)
        hook_parser.add_argument("--destination", required=True)
        hook_parser.add_argument("--template", required=True)
        hook_parser.add_argument("--home", required=True)
    args = parser.parse_args()
    if args.command == "scan":
        return scan(args.paths)
    if args.command == "json-validate":
        return validate_json(args.path)
    if args.command == "merge-hooks":
        return merge_hooks(args.destination, args.template, args.home)
    return remove_hooks(args.destination, args.template, args.home)


if __name__ == "__main__":
    raise SystemExit(main())
