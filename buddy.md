---
description: "Hatch, view, and interact with your Claude Buddy - a virtual terminal pet companion. Usage: /buddy, /buddy card, /buddy pet, /buddy mute, /buddy unmute, /buddy off"
---

# /buddy - Virtual Terminal Pet Companion

When the user invokes `/buddy`, run the buddy script and present the output according to the skill instructions.

## Subcommand Routing

Parse the user's input after `/buddy` to determine the subcommand:

| User types | Run this |
|---|---|
| `/buddy` (no args) | Check if `~/.claude/buddy.json` exists. If NO: run `hatch`. If YES: run `status`. |
| `/buddy pet` | Run `pet` |
| `/buddy card` | Run `card` |
| `/buddy mute` | Run `mute` |
| `/buddy unmute` | Run `unmute` |
| `/buddy off` | Run `off` |

## Execution

Run the script via Bash:

```bash
node ~/.claude/skills/buddy/buddy.mjs <subcommand>
```

The script outputs JSON to stdout. Parse it and present the output according to the `SKILL.md` in `~/.claude/skills/buddy/`.

## Presentation Rules

1. **For `hatch` and `already_hatched`**: Display the `rendered` field as-is in a code block. Add excitement!
2. **For `card`**: Display the `rendered` field as-is in a code block.
3. **For `pet`**: Display the `rendered` field as-is in a code block.
4. **For `status`**: Show the buddy sprite and a short in-character greeting based on `soul.personality`.
5. **For `not_hatched`**: Tell the user to run `/buddy` to hatch their buddy.
6. **For `muted`/`unmuted`/`hidden`**: Confirm the action with a short message.

Always display ASCII art and stat cards inside code blocks (``` ```) so they render correctly in the terminal.
