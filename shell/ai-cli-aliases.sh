# Loaded from ~/.bashrc by ai-cli-dotfiles. Official commands remain untouched.
alias cyolo='cursor-st --yolo'
alias cagent='cursor-st'
alias cdoctor='cursor-st --doctor'

# Composer 2.5 + Grok 4.6 Cursor hierarchy.
alias groky='cursor-st --groky --yolo'
alias groky-safe='cursor-st --groky'

# Codex has no --yolo. Enable these only when Codex is installed.
if command -v codex >/dev/null 2>&1; then
  alias cdx='codex'
  if command -v codex-st >/dev/null 2>&1; then
    # This uses GPT Hierarchy v2 and bypasses confirmations and sandboxing.
    # Use only in an externally sandboxed environment.
    alias codexy='codex-st --dangerously-bypass-approvals-and-sandbox'
  fi
fi
