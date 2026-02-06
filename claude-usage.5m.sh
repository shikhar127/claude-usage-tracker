#!/bin/bash

# <xbar.title>Claude Usage</xbar.title>
# <xbar.version>v3.0</xbar.version>
# <xbar.author>Claude</xbar.author>
# <xbar.author.github>anthropics</xbar.author.github>
# <xbar.desc>Beautiful Claude usage tracker with session monitoring</xbar.desc>
# <xbar.dependencies>bash,jq</xbar.dependencies>

STATS_FILE="$HOME/.claude/stats-cache.json"
HISTORY_FILE="$HOME/.claude/history.jsonl"
CONFIG_FILE="$HOME/.claude/usage-config.json"
SESSION_FILE="$HOME/.claude/current-session-usage.json"

# Default limits
WEEKLY_MESSAGE_LIMIT=5000
SESSION_TOKEN_LIMIT=200000

# Load config
if [[ -f "$CONFIG_FILE" ]] && command -v jq &> /dev/null; then
  WEEKLY_MESSAGE_LIMIT=$(jq -r '.weeklyMessageLimit // 5000' "$CONFIG_FILE")
  SESSION_TOKEN_LIMIT=$(jq -r '.sessionTokenLimit // 200000' "$CONFIG_FILE")
fi

# Get current session usage from active session
get_session_usage() {
  if [[ -f "$SESSION_FILE" ]]; then
    local age=$(( $(date +%s) - $(stat -f %m "$SESSION_FILE" 2>/dev/null || stat -c %Y "$SESSION_FILE" 2>/dev/null) ))
    if [[ $age -lt 600 ]]; then  # Less than 10 minutes old
      cat "$SESSION_FILE"
      return
    fi
  fi
  echo '{"tokens": 0, "percentage": 0}'
}

# Progress bar with gradient effect
progress_bar() {
  local percentage=$1
  local width=15
  local filled=$((percentage * width / 100))
  local empty=$((width - filled))

  local bar=""

  # Use different characters based on fill level
  for ((i=0; i<filled; i++)); do
    if [[ $i -eq $filled-1 ]] && [[ $filled -lt $width ]]; then
      bar+="▓"  # Gradient edge
    else
      bar+="█"
    fi
  done

  for ((i=0; i<empty; i++)); do bar+="░"; done
  echo "$bar"
}

# Get color and emoji based on percentage
get_status() {
  local pct=$1
  local type=$2

  if [[ $pct -lt 40 ]]; then
    echo "🟢|#10b981"
  elif [[ $pct -lt 70 ]]; then
    echo "🟡|#f59e0b"
  elif [[ $pct -lt 90 ]]; then
    echo "🟠|#fb923c"
  else
    echo "🔴|#ef4444"
  fi
}

# Calculate time until reset (assume weekly reset on Monday 00:00)
time_until_reset() {
  local now=$(date +%s)
  local current_day=$(date +%u)  # 1=Monday, 7=Sunday
  local days_until_monday=$((8 - current_day))
  if [[ $days_until_monday -eq 8 ]]; then days_until_monday=7; fi

  local next_monday=$(date -v +${days_until_monday}d -v 0H -v 0M -v 0S +%s 2>/dev/null || \
                      date -d "+${days_until_monday} days 00:00:00" +%s 2>/dev/null)
  local diff=$((next_monday - now))

  local days=$((diff / 86400))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))

  if [[ $days -gt 0 ]]; then
    echo "${days}d ${hours}h"
  else
    echo "${hours}h ${mins}m"
  fi
}

if [[ ! -f "$STATS_FILE" ]]; then
  echo "⚡︎"
  echo "---"
  echo "No stats available"
  exit 0
fi

if ! command -v jq &> /dev/null; then
  echo "⚡︎"
  echo "---"
  echo "Install jq: brew install jq | bash=brew args=install,jq terminal=true"
  exit 0
fi

# Get session usage
session_data=$(get_session_usage)
session_tokens=$(echo "$session_data" | jq -r '.tokens // 0')
session_pct=$(echo "$session_data" | jq -r '.percentage // 0')

# Get weekly stats
today_messages=$(jq -r '.dailyActivity[-1].messageCount // 0' "$STATS_FILE")
weekly_messages=$(jq '[.dailyActivity[-7:][].messageCount] | add' "$STATS_FILE")
weekly_pct=$((weekly_messages * 100 / WEEKLY_MESSAGE_LIMIT))

# Menu bar - show worst usage
worst_pct=$session_pct
if [[ $weekly_pct -gt $session_pct ]]; then
  worst_pct=$weekly_pct
fi

if [[ $worst_pct -lt 40 ]]; then
  echo "⚡︎ ${worst_pct}%"
elif [[ $worst_pct -lt 70 ]]; then
  echo "⚡︎ ${worst_pct}% | color=#f59e0b"
elif [[ $worst_pct -lt 90 ]]; then
  echo "⚡︎ ${worst_pct}% | color=#fb923c"
else
  echo "⚡︎ ${worst_pct}% | color=#ef4444"
fi

# Dropdown menu with modern design
echo "---"
echo "Claude Sonnet 4.5 | size=16 color=#6366f1"
echo "---"

# Session usage
session_status=$(get_status $session_pct "session")
session_emoji=$(echo "$session_status" | cut -d'|' -f1)
session_color=$(echo "$session_status" | cut -d'|' -f2)

echo "┌─ Session | size=13 color=#8b5cf6"
if [[ $session_tokens -gt 0 ]]; then
  echo "│  $(progress_bar $session_pct)  ${session_pct}% | font=Monaco size=11 color=$session_color"
  echo "│  $(printf "%'d" $session_tokens) / $(printf "%'d" $SESSION_TOKEN_LIMIT) tokens | size=11 color=#6b7280"
  echo "│  Active now | size=10 color=#9ca3af"
else
  echo "│  $(progress_bar 0)  0% | font=Monaco size=11 color=#10b981"
  echo "│  No active session | size=11 color=#6b7280"
fi
echo "│"

# Weekly usage
weekly_status=$(get_status $weekly_pct "weekly")
weekly_emoji=$(echo "$weekly_status" | cut -d'|' -f1)
weekly_color=$(echo "$weekly_status" | cut -d'|' -f2)
reset_time=$(time_until_reset)

echo "├─ Weekly | size=13 color=#8b5cf6"
echo "│  $(progress_bar $weekly_pct)  ${weekly_pct}% | font=Monaco size=11 color=$weekly_color"
echo "│  $(printf "%'d" $weekly_messages) / $(printf "%'d" $WEEKLY_MESSAGE_LIMIT) messages | size=11 color=#6b7280"
echo "│  Resets in $reset_time | size=10 color=#9ca3af"
echo "│"

# Model info
echo "└─ Model | size=13 color=#8b5cf6"
echo "   claude-sonnet-4.5-20250929 | size=10 font=Monaco color=#6b7280"

echo "---"

# Quick stats
echo "Today: $today_messages msgs | size=11 color=#3b82f6"

echo "---"

# Actions
echo "💬 Open Claude | bash=/Users/shikhar/.local/bin/claude terminal=true"
echo "🔄 Update Session Usage | bash=/Users/shikhar/.local/bin/claude-session-update terminal=false refresh=true"
echo "📊 View Details | bash=open args=$STATS_FILE"
echo "⚙️ Settings ($WEEKLY_MESSAGE_LIMIT/wk) | bash=open args=-e,$CONFIG_FILE"
echo "♻️ Refresh Now | refresh=true"
