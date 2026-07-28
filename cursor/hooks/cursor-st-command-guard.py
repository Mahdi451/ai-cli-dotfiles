#!/usr/bin/env python3
"""Block a small set of clearly destructive shell commands in Cursor agents."""
import json
import os
import re
import sys

RULES = [
    (re.compile(r"(^|[;&|]\s*)(?:\S*/)?git(?:\s+-C\s+\S+)*\s+reset\s+--hard\b", re.I), "git reset --hard"),
    (re.compile(r"(^|[;&|]\s*)(?:\S*/)?git(?:\s+-C\s+\S+)*\s+clean\s+-[^\n]*(?:f[^\n]*d|d[^\n]*f)\b", re.I), "git clean with force/delete"),
    (re.compile(r"(^|[;&|]\s*)(?:\S*/)?git\s+push\b[^\n]*(--force(?:-with-lease)?|\s-f(?:\s|$))", re.I), "force push"),
    (re.compile(r"(^|[;&|]\s*)(?:\S*/)?git\s+branch\s+-D\b", re.I), "forced branch deletion"),
    (re.compile(r"(^|[;&|]\s*)rm\s+-[^\n]*(?:r[^\n]*f|f[^\n]*r)[^\n]*\s+(?:/|~|\$HOME)(?:\s|$)", re.I), "recursive deletion of root/home"),
]


def command_from(payload):
    for key in ("command",):
        if isinstance(payload.get(key), str):
            return payload[key]
    for key in ("tool_input", "input", "args", "parameters"):
        value = payload.get(key)
        if isinstance(value, dict) and isinstance(value.get("command"), str):
            return value["command"]
    return ""


def main():
    if os.environ.get("CURSOR_ST_ALLOW_DANGEROUS") == "1":
        print("{}")
        return 0
    try:
        payload = json.load(sys.stdin)
    except Exception:
        print("{}")  # Fail open on unknown event payloads.
        return 0
    command = command_from(payload)
    for pattern, label in RULES:
        if pattern.search(command):
            print(json.dumps({
                "permission": "deny",
                "user_message": f"Blocked by cursor-st safety guard: {label}. Review and run it manually if intended.",
                "agent_message": "Choose a reversible alternative and preserve user work.",
            }))
            return 0
    print("{}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
