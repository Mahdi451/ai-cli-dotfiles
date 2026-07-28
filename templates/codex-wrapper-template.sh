#!/usr/bin/env bash
set -euo pipefail

command -v codex >/dev/null 2>&1 || {
  printf '%s\n' 'Codex CLI is not installed.' >&2
  exit 1
}

exec codex "$@"
