---
description: "Hatch, view, and interact with your Claude Buddy - a virtual terminal pet companion. Usage: /buddy, /buddy card, /buddy pet, /buddy mute, /buddy unmute, /buddy off, /buddy game, /buddy feed, /buddy mood, /buddy streak, /buddy achievements, /buddy pomodoro, /buddy eyes, /buddy hat, /buddy reroll"
---

# /buddy - Virtual Terminal Pet Companion

When the user invokes `/buddy`, run the buddy script and present the output according to these rules.

## Subcommand Routing

Parse the user's input after `/buddy` to determine the subcommand:

| User types | Run this |
|---|---|
| `/buddy` (no args) | Check if `~/.claude/buddy.json` exists. If NO: run `hatch`. If YES: run `status`. |
| `/buddy pet` | Run `pet` |
| `/buddy card` | Run `card` |
| `/buddy mood` | Run `mood` |
| `/buddy feed` | Run `feed` |
| `/buddy game` | Run `game` |
| `/buddy streak` | Run `streak` |
| `/buddy achievements` | Run `achievements` |
| `/buddy pomodoro [start/stop]` | Run `pomodoro` with optional subcommand |
| `/buddy eyes [char/reset]` | Run `eyes` with optional argument |
| `/buddy hat [name/reset]` | Run `hat` with optional argument |
| `/buddy reroll` | Run `reroll` |
| `/buddy mute` | Run `mute` |
| `/buddy unmute` | Run `unmute` |
| `/buddy off` | Run `off` |

## Execution

Run the script via Bash:

```bash
node ~/.claude/skills/buddy/buddy.mjs <subcommand> [args...]
```

The script outputs JSON to stdout. Parse the JSON and present the output.

## Stat Growth

Many actions return a `statGrowth` field: `{ stat: "SNARK", amount: 1 }`. When present, ALWAYS show it prominently as a short celebratory line, e.g.:

> 📈 SNARK +1!

This applies to `pet` (SNARK +1), `game` (CHAOS +1), and `pomodoro` completed (PATIENCE +2).

## Presentation Rules

1. **For `hatch` and `already_hatched`**: Display the `rendered` field in a code block. Add excitement based on rarity!
2. **For `card`**: Display the `renderedMarkdown` field directly as markdown (NOT in a code block). It has formatted headers, emoji stat bars, bold values, and italic growth hints. Only fall back to `rendered` in a code block if `renderedMarkdown` is missing.
3. **For `pet`**: Display the `rendered` field in a code block. Show `statGrowth` if present. Add a short species-appropriate reaction based on `soul.personality`.
4. **For `game`**: Display the `rendered` field. Show `statGrowth` if present.
5. **For `mood`**: Display the `rendered` field.
6. **For `feed`**: Show the `reaction` field and energy update.
7. **For `pomodoro`**: Show timer status. If `status` is `completed`, celebrate and show `statGrowth`.
8. **For `streak`**: Display the `rendered` field.
9. **For `achievements`**: Display the `rendered` field.
10. **For `reroll`**: Display the `rendered` field in a code block. Celebrate the new buddy!
11. **For `status`**: Show the buddy sprite in a code block and a short in-character greeting based on `soul.personality`.
12. **For `not_hatched`**: Tell the user to run `/buddy` to hatch their buddy.
13. **For `muted`/`unmuted`/`hidden`**: Confirm the action with a short message.

Display ASCII art and sprites inside code blocks (```) so they render correctly.
