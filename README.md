# Claude Usage Tracker

A beautiful macOS menu bar app for tracking Claude Code usage with real-time session monitoring and weekly limits.

## Features

- 🎨 **Modern Design** - Clean UI with progress bars and color-coded status indicators
- ⚡ **Real-time Session Tracking** - Monitor your current session's token usage
- 📊 **Weekly Usage Stats** - Track messages against your weekly limit
- 🔔 **Smart Alerts** - Color changes as you approach limits (green → yellow → orange → red)
- ⏱️ **Reset Timer** - Shows time until your weekly limit resets
- 📈 **Historical Data** - View all-time stats and recent activity

## Preview

```
⚡︎ 76%
━━━━━━━━━━━━━━━━━━━━━━
Claude Sonnet 4.5

┌─ Session
│  ░░░░░░░░░░░░░░░  0%
│  No active session
│
├─ Weekly
│  ██████████▓░░░░  76%
│  3,809 / 5,000 messages
│  Resets in 2d 7h
│
└─ Model
   claude-sonnet-4.5-20250929
```

## Installation

### 1. Install SwiftBar

```bash
brew install --cask swiftbar
```

### 2. Set up plugin directory

```bash
mkdir -p ~/swiftbar-plugins
```

### 3. Install the plugin

```bash
cd ~/swiftbar-plugins
curl -O https://raw.githubusercontent.com/shikhar127/claude-usage-tracker/main/claude-usage.5m.sh
chmod +x claude-usage.5m.sh
```

### 4. Configure SwiftBar

1. Open SwiftBar
2. Click SwiftBar icon → Preferences
3. Set plugin folder to `~/swiftbar-plugins`

### 5. Install session updater

For session usage tracking:

```bash
curl -o ~/.local/bin/claude-session-update https://raw.githubusercontent.com/shikhar127/claude-usage-tracker/main/claude-session-update
chmod +x ~/.local/bin/claude-session-update
```

### 6. Configure your limits

```bash
cp config-example.json ~/.claude/usage-config.json
# Edit the file to set your weekly message limit
nano ~/.claude/usage-config.json
```

## Configuration

Edit `~/.claude/usage-config.json`:

```json
{
  "weeklyMessageLimit": 5000,
  "sessionTokenLimit": 200000
}
```

Adjust `weeklyMessageLimit` based on your Claude plan:
- **Claude Pro**: ~5,000 messages/week
- **Claude Team**: Varies by plan
- **API Usage**: Custom limits

## Status Colors

| Color | Percentage | Meaning |
|-------|------------|---------|
| 🟢 Green | < 40% | Safe - plenty of usage left |
| 🟡 Yellow | 40-70% | Moderate - keep an eye on it |
| 🟠 Orange | 70-90% | High - approaching limit |
| 🔴 Red | > 90% | Critical - near limit |

## Requirements

- macOS 11.0 or later
- [SwiftBar](https://swiftbar.app/)
- [jq](https://stedolan.github.io/jq/) - Install with `brew install jq`
- Claude Code CLI

## How It Works

The plugin reads Claude Code's stats cache (`~/.claude/stats-cache.json`) to track your message history and calculates:

- **Session Usage**: Updated manually or via button click (Claude doesn't expose token counts to external scripts)
- **Weekly Usage**: Sum of messages from last 7 days (automatic)
- **Daily Activity**: Today's message count (automatic)

Weekly limits reset every Monday at 00:00.

### Updating Session Usage

**From the menu bar:**
Click "🔄 Update Session Usage" to auto-estimate based on recent activity

**Manual update (when in Claude Code):**
```bash
# Check /context in Claude to see your token count
# Then update manually:
claude-session-update <tokens> <percentage>

# Example: if you have 75,613 tokens (38%)
claude-session-update 75613 38
```

**Auto-estimate:**
```bash
# Estimates based on message count
claude-session-update
```

## Troubleshooting

**Plugin not showing up:**
- Make sure SwiftBar is running
- Check that the plugin folder is set correctly in SwiftBar Preferences
- Ensure the script is executable: `chmod +x claude-usage.5m.sh`

**"Install jq" message:**
```bash
brew install jq
```

**Session usage shows 0 or "No active session":**
- Session tracking is manual - click "🔄 Update Session Usage" in the menu
- Or run `claude-session-update` to estimate from recent activity
- For accurate counts, check `/context` in Claude and update manually

**Menu bar not updating:**
- SwiftBar refreshes every 5 minutes automatically
- Click "♻️ Refresh Now" to force immediate update
- Or run: `open "swiftbar://refreshallplugins"`

## Credits

Built for Claude Code users who want better visibility into their usage patterns.

## License

MIT License - feel free to modify and share!
