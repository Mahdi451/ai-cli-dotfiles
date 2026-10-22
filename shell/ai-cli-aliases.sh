# Loaded from ~/.bashrc by ai-cli-dotfiles. Official commands remain untouched.

# Original Sol/Terra/Luna Cursor hierarchy. Fast is enforced off by cursor-st.
alias cagent='cursor-st'
alias cursory='cursor-st --yolo'
alias cdoctor='cursor-st --doctor'

# Composer 2.5 + Grok 4.7 Cursor hierarchy. Fast is enforced off by cursor-st.
alias groky='cursor-st --groky --yolo'
alias groky-safe='cursor-st --groky'

# Codex GPT Hierarchy v2. `cyolo` is the canonical full-approval home alias.
# Codex has no Cursor Fast toggle.
if command -v codex >/dev/null 2>&1; then
  alias cdx='codex'
  if command -v codex-st >/dev/null 2>&1; then
    # Primary home GPT hierarchy alias: full approvals / no Codex sandbox.
    # Use only in an externally sandboxed or otherwise trusted environment.
    alias cyolo='codex-st --dangerously-bypass-approvals-and-sandbox'

    # Backward-compatible name retained for existing shells/scripts.
    alias codexy='codex-st --dangerously-bypass-approvals-and-sandbox'
  fi
fi
