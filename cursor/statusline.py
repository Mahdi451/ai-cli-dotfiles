#!/usr/bin/env python3
import json
import os
import re
import sys
import unicodedata
from decimal import Decimal, ROUND_HALF_UP

RESET = "\033[0m"
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
DIM = "\033[90m"
ANSI = re.compile(r"\033\[[0-9;]*m")


def visible_length(text):
    plain = ANSI.sub("", text)
    return sum(
        2 if unicodedata.east_asian_width(char) in ("W", "F") else 1
        for char in plain
    )


def truncate_text(text, width):
    if visible_length(text) <= width:
        return text
    if width <= 1:
        return "…" if width == 1 else ""
    result = []
    used = 0
    for char in text:
        char_width = 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1
        if used + char_width > width - 1:
            break
        result.append(char)
        used += char_width
    return "".join(result) + "…"


def context_color(percent):
    if percent < 50:
        return GREEN
    if percent < 80:
        return YELLOW
    return RED


def display_path(path):
    if not path:
        return ""
    path = os.path.normpath(path)
    home = os.path.expanduser("~")
    if path == home:
        return "~"
    if path.startswith(home + os.sep):
        return "~" + path[len(home):]
    return path


def compact_path(path, level):
    if not path or level == 0:
        return path
    has_home_prefix = path.startswith("~/")
    relative = path[2:] if has_home_prefix else path
    pieces = [piece for piece in relative.split(os.sep) if piece]
    if not pieces:
        return path
    prefix = "~/" if has_home_prefix else ""
    if level == 1 and len(pieces) >= 2:
        return f"{prefix}…/{pieces[-2]}/{pieces[-1]}"
    return f"{prefix}…/{pieces[-1]}"


def format_prompt_duration(duration_ms):
    if not isinstance(duration_ms, (int, float)) or duration_ms < 0:
        return ""
    millis = Decimal(str(duration_ms))
    if millis < 1000:
        shown = int(millis.quantize(Decimal("1"), rounding=ROUND_HALF_UP))
        if shown >= 1000:
            return "⏱ 1.0s"
        return f"⏱ {shown}ms"
    seconds = millis / Decimal(1000)
    if seconds < 60:
        shown = seconds.quantize(Decimal("0.1"), rounding=ROUND_HALF_UP)
        if shown < 60:
            return f"⏱ {shown:.1f}s"
        seconds = Decimal(60)
    total = int(seconds.quantize(Decimal("1"), rounding=ROUND_HALF_UP))
    hours, remainder = divmod(total, 3600)
    minutes, secs = divmod(remainder, 60)
    if hours:
        return f"⏱ {hours}h {minutes:02d}m {secs:02d}s"
    return f"⏱ {minutes}m {secs:02d}s"


def previous_prompt_duration():
    cursor_home = os.environ.get("CURSOR_HOME", os.path.expanduser("~/.cursor"))
    path = os.path.join(cursor_home, "prompt-timing.json")
    try:
        with open(path, encoding="utf-8") as handle:
            data = json.load(handle)
        return format_prompt_duration((data or {}).get("last_ms"))
    except (OSError, json.JSONDecodeError, TypeError, ValueError):
        return ""


def access_label():
    cursor_home = os.environ.get("CURSOR_HOME", os.path.expanduser("~/.cursor"))
    config_path = os.path.join(cursor_home, "cli-config.json")
    try:
        with open(config_path, encoding="utf-8") as handle:
            config = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return ""
    approval = str(config.get("approvalMode", "allowlist")).lower()
    sandbox = str((config.get("sandbox") or {}).get("mode", "disabled")).lower()
    if approval == "unrestricted" and sandbox == "disabled":
        return "Full Access"
    if sandbox == "enabled":
        return "Sandboxed"
    return "Approval Required"


try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, TypeError):
    sys.exit(1)

model_data = data.get("model") or {}
model = str(
    model_data.get("id")
    or model_data.get("display_name")
    or "agent"
)
parameter = str(model_data.get("param_summary") or "").strip("() ").lower()
if not parameter and model_data.get("max_mode") is True:
    parameter = "max"
if parameter and parameter not in model.lower():
    model = f"{model} {parameter}"

cwd = data.get("cwd") or (data.get("workspace") or {}).get("current_dir") or ""
path = display_path(str(cwd))
context = data.get("context_window") or {}
used = context.get("used_percentage")
percent = float(used) if used is not None else None
access = access_label()
duration = previous_prompt_duration()
width = max(1, int(data.get("render_width_chars") or 80))
separator = f" {DIM}·{RESET} "


def make_line(
    path_value,
    compact=False,
    include_access=True,
    include_model=True,
    include_duration=True,
    model_value=None,
):
    parts = []
    if include_model:
        parts.append(f"{CYAN}{model if model_value is None else model_value}{RESET}")
    if include_duration and duration:
        parts.append(f"{DIM}{duration}{RESET}")
    if path_value:
        parts.append(f"{DIM}{path_value}{RESET}")
    if percent is not None:
        context_label = (
            f"ctx {int(percent)}%"
            if compact
            else f"Context {int(percent)}% used"
        )
        parts.append(
            f"{context_color(percent)}{context_label}{RESET}"
        )
    if access and include_access:
        color = GREEN if access == "Full Access" else YELLOW
        compact_access_labels = {
            "Full Access": "Full",
            "Sandboxed": "Sandbox",
            "Approval Required": "Approval",
        }
        access_label = compact_access_labels.get(access, access) if compact else access
        parts.append(f"{color}{access_label}{RESET}")
    return separator.join(parts)


line = make_line(path)
for level in (1, 2):
    if visible_length(line) <= width:
        break
    line = make_line(compact_path(path, level))
if visible_length(line) > width:
    line = make_line("")
if visible_length(line) > width:
    line = make_line("", compact=True)
if visible_length(line) > width:
    line = make_line("", compact=True, include_access=False)
if visible_length(line) > width:
    context_line = make_line(
        "",
        compact=True,
        include_access=False,
        include_model=False,
    )
    model_width = width
    if context_line:
        model_width -= visible_length(separator) + visible_length(context_line)
    if model_width > 0:
        line = make_line(
            "",
            compact=True,
            include_access=False,
            model_value=truncate_text(model, model_width),
        )
    else:
        line = context_line
if visible_length(line) > width:
    line = make_line("", compact=True, include_access=False, include_duration=False)
if visible_length(line) > width:
    line = f"{CYAN}{truncate_text(model, width)}{RESET}"

print(line)
