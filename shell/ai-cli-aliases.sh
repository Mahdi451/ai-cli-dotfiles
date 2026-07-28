# Loaded from ~/.bashrc by ai-cli-dotfiles. Official commands remain untouched.
alias cyolo='cursor-st --yolo'
alias cagent='cursor-st'
alias cdoctor='cursor-st --doctor'

# Codex CLI 0.145.0 has no --yolo. Enable these only when codex is installed.
if command -v codex >/dev/null 2>&1; then
  alias cdx='codex'
  # This bypasses confirmations and sandboxing; use only in an externally
  # sandboxed environment after reviewing the risks.
  alias codexy='codex --dangerously-bypass-approvals-and-sandbox'
fi
