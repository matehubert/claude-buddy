#!/bin/bash
# Claude Buddy installer
set -e

REPO="https://raw.githubusercontent.com/matehubert/claude-buddy/main"

echo "Installing Claude Buddy..."

mkdir -p ~/.claude/commands ~/.claude/skills/buddy

curl -fsSL "$REPO/buddy.md" -o ~/.claude/commands/buddy.md
curl -fsSL "$REPO/buddy.mjs" -o ~/.claude/skills/buddy/buddy.mjs
curl -fsSL "$REPO/SKILL.md" -o ~/.claude/skills/buddy/SKILL.md
curl -fsSL "$REPO/buddy-hook.mjs" -o ~/.claude/skills/buddy/buddy-hook.mjs
chmod +x ~/.claude/skills/buddy/buddy-hook.mjs

# Register Claude Code hooks for buddy awareness
SETTINGS="$HOME/.claude/settings.json"
HOOK_CMD="node $HOME/.claude/skills/buddy/buddy-hook.mjs"

if command -v node >/dev/null 2>&1; then
  node -e "
    const fs = require('fs');
    const path = '$SETTINGS';
    let settings = {};
    try { settings = JSON.parse(fs.readFileSync(path, 'utf8')); } catch {}
    if (!settings.hooks) settings.hooks = {};
    const hookTypes = ['PostToolUse', 'SessionStart', 'Stop'];
    const cmd = '$HOOK_CMD';
    for (const type of hookTypes) {
      if (!settings.hooks[type]) settings.hooks[type] = [];
      const exists = settings.hooks[type].some(h => h.command && h.command.includes('buddy-hook'));
      if (!exists) {
        settings.hooks[type].push({
          type: 'command',
          command: cmd
        });
      }
    }
    fs.writeFileSync(path, JSON.stringify(settings, null, 2));
  "
  echo "Claude Code hooks registered."
fi

echo "Claude Buddy installed! Type /buddy in Claude Code to hatch your companion."
