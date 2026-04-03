#!/bin/bash
# Claude Buddy installer
set -e

REPO="https://raw.githubusercontent.com/matehubert/claude-buddy/main"

echo "Installing Claude Buddy..."

mkdir -p ~/.claude/commands ~/.claude/skills/buddy

curl -fsSL "$REPO/buddy.md" -o ~/.claude/commands/buddy.md
curl -fsSL "$REPO/buddy.mjs" -o ~/.claude/skills/buddy/buddy.mjs
curl -fsSL "$REPO/SKILL.md" -o ~/.claude/skills/buddy/SKILL.md

echo "Claude Buddy installed! Type /buddy in Claude Code to hatch your companion."
