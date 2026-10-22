#!/usr/bin/env python3
"""Record wall-clock duration from prompt submit until the agent turn stops."""
import json
import os
import sys
import tempfile
import time


def cursor_home():
    return os.environ.get("CURSOR_HOME", os.path.expanduser("~/.cursor"))


def state_path():
    return os.path.join(cursor_home(), "prompt-timing.json")


def empty_state():
    return {"open": {}, "latest": {}, "last_ms": None}


def load_state():
    try:
        with open(state_path(), encoding="utf-8") as handle:
            data = json.load(handle)
    except (OSError, json.JSONDecodeError):
        return empty_state()
    if not isinstance(data, dict):
        return empty_state()
    open_turns = data.get("open") if isinstance(data.get("open"), dict) else {}
    latest = data.get("latest") if isinstance(data.get("latest"), dict) else {}
    last_ms = data.get("last_ms")
    if not isinstance(last_ms, (int, float)) or last_ms < 0:
        last_ms = None
    return {"open": open_turns, "latest": latest, "last_ms": last_ms}


def save_state(state):
    path = state_path()
    directory = os.path.dirname(path)
    os.makedirs(directory, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=".prompt-timing.", dir=directory)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(
                {
                    "open": state["open"],
                    "latest": state["latest"],
                    "last_ms": state["last_ms"],
                },
                handle,
                separators=(",", ":"),
            )
            handle.write("\n")
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    except Exception:
        try:
            os.unlink(temporary)
        except OSError:
            pass
        raise


def text_field(payload, key):
    value = payload.get(key)
    if isinstance(value, str):
        return value.strip()
    return ""


def remember_start(state, payload, now_ms):
    generation = text_field(payload, "generation_id")
    session = text_field(payload, "session_id") or text_field(payload, "conversation_id")
    key = generation or session
    if not key:
        return
    state["open"][key] = now_ms
    if session:
        state["latest"][session] = key
    if len(state["open"]) > 20:
        ordered = sorted(state["open"].items(), key=lambda item: item[1])
        state["open"] = dict(ordered[-20:])
        live = set(state["open"])
        state["latest"] = {
            session_id: turn
            for session_id, turn in state["latest"].items()
            if turn in live
        }


def complete_turn(state, payload, now_ms):
    generation = text_field(payload, "generation_id")
    session = text_field(payload, "session_id") or text_field(payload, "conversation_id")
    key = generation or (state["latest"].get(session) if session else "") or session
    if not key:
        return False
    started = state["open"].pop(key, None)
    if started is None and session:
        fallback = state["latest"].get(session)
        if fallback and fallback != key:
            started = state["open"].pop(fallback, None)
            key = fallback
    if session and state["latest"].get(session) == key:
        state["latest"].pop(session, None)
    if not isinstance(started, (int, float)):
        return False
    duration = now_ms - float(started)
    if duration < 0:
        return False
    state["last_ms"] = duration
    return True


def main():
    print("{}")
    try:
        payload = json.load(sys.stdin)
    except Exception:
        return 0
    if not isinstance(payload, dict):
        return 0
    event = text_field(payload, "hook_event_name")
    if event not in {"beforeSubmitPrompt", "stop"}:
        return 0
    try:
        state = load_state()
        now_ms = time.time() * 1000.0
        if event == "beforeSubmitPrompt":
            remember_start(state, payload, now_ms)
            save_state(state)
        elif complete_turn(state, payload, now_ms):
            save_state(state)
    except Exception:
        return 0
    return 0


if __name__ == "__main__":
    sys.exit(main())
