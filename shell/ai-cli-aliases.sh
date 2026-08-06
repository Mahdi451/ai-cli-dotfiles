# Loaded from ~/.bashrc by ai-cli-dotfiles. Official commands remain untouched.
alias cyolo='cursor-st --yolo'
alias cagent='cursor-st'
alias cdoctor='cursor-st --doctor'

# Codex has no --yolo. Enable these only when Codex is installed.
if command -v codex >/dev/null 2>&1; then
  alias cdx='codex'
  if command -v codex-st >/dev/null 2>&1; then
    # This uses the Sol/Terra/Luna hierarchy and bypasses confirmations and
    # sandboxing. Use only in an externally sandboxed environment.
    alias codexy='codex-st --dangerously-bypass-approvals-and-sandbox'
  fi
fi
