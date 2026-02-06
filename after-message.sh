#!/bin/bash
# Hook to track session usage after each message

SESSION_FILE="$HOME/.claude/current-session-usage.json"
SESSION_TOKEN_LIMIT=200000

# Get token usage from environment or stdin
# Claude Code provides CLAUDE_CONTEXT_TOKENS in some cases
if [[ -n "$CLAUDE_CONTEXT_TOKENS" ]]; then
  tokens=$CLAUDE_CONTEXT_TOKENS
else
  # Try to extract from context info if available
  tokens=0
fi

# Calculate percentage
percentage=$((tokens * 100 / SESSION_TOKEN_LIMIT))

# Write to session file
cat > "$SESSION_FILE" << EOF
{
  "tokens": $tokens,
  "percentage": $percentage,
  "timestamp": $(date +%s),
  "session_id": "$CLAUDE_SESSION_ID"
}
EOF
