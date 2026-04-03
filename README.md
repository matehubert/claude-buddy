# Claude Buddy

A virtual terminal pet companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Your buddy is a deterministically generated tamagotchi that lives in your terminal, reacts to your coding activity via the Anthropic API, and keeps you company while you code.

## Features

- **18 species**: duck, goose, blob, cat, dragon, octopus, owl, penguin, turtle, snail, ghost, axolotl, capybara, cactus, robot, rabbit, mushroom, chonk
- **5 rarity tiers**: Common (60%), Uncommon (25%), Rare (10%), Epic (4%), Legendary (1%)
- **Deterministic**: Same user always gets the same buddy (FNV-1a + Mulberry32 PRNG)
- **LLM-powered reactions**: Your buddy reacts to your coding via the `buddy_react` API
- **ASCII art**: Charming terminal sprites with customizable eyes and hats
- **Stats**: DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK (0-100)

## Installation

Copy the files into your Claude Code config directory:

```bash
# Create directories
mkdir -p ~/.claude/commands ~/.claude/skills/buddy

# Copy files
cp buddy.md ~/.claude/commands/buddy.md
cp buddy.mjs ~/.claude/skills/buddy/buddy.mjs
cp SKILL.md ~/.claude/skills/buddy/SKILL.md
```

Or use the one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/matehubert/claude-buddy/main/install.sh | bash
```

## Usage

In Claude Code, type:

| Command | Description |
|---------|-------------|
| `/buddy` | Hatch your buddy (first time) or check on them |
| `/buddy card` | View your buddy's stat card |
| `/buddy pet` | Pet your buddy |
| `/buddy mute` | Mute buddy reactions |
| `/buddy unmute` | Unmute buddy reactions |
| `/buddy off` | Hide buddy |

## How It Works

Your buddy is generated deterministically from your Claude account UUID using FNV-1a hashing and Mulberry32 PRNG. The same account always produces the same species, rarity, stats, eyes, and hat.

Reactions are powered by the Anthropic `buddy_react` API endpoint, using your existing Claude Code OAuth credentials (read from macOS Keychain). This gives your buddy a unique personality that responds to your coding context.

## Requirements

- Claude Code v2.1.89+
- Claude Pro/Max subscription
- macOS (for Keychain credential access)

## File Structure

```
~/.claude/
├── commands/buddy.md          # Slash command registration
├── skills/buddy/
│   ├── SKILL.md               # Presentation instructions for Claude
│   └── buddy.mjs              # Core script (generation, rendering, API)
└── buddy.json                 # Persistent buddy data (created on hatch)
```

## License

MIT
