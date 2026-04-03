# Claude Buddy

A virtual terminal pet companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Your buddy is a deterministically generated tamagotchi that lives in your terminal, reacts to your coding activity via the Anthropic API, and keeps you company while you code.

## Example

```
╔═════════════════════════════════════════╗
║               Pike                      ║
║     @@        ★ Common Snail            ║
║   (◉  ◉)_                               ║
║   /  ___/o    Hatched: 2026-04-03       ║
║  /__(                                   ║
║                                         ║
║  DEBUGGING  [████░░░░░░░░░░░░]  28      ║
║  PATIENCE   [█████░░░░░░░░░░░]  33      ║
║  CHAOS      [░░░░░░░░░░░░░░░░]   1      ║
║  WISDOM     [██████░░░░░░░░░░]  39      ║
║  SNARK      [█████████████░░░]  81      ║
╚═════════════════════════════════════════╝
```

## Features

- **18 species** with unique ASCII sprites and personalities
- **5 rarity tiers**: Common (60%), Uncommon (25%), Rare (10%), Epic (4%), Legendary (1%)
- **Deterministic**: Same user always gets the same buddy (FNV-1a + Mulberry32 PRNG)
- **LLM-powered reactions**: Your buddy reacts to your coding via the `buddy_react` API (~100 tokens/call, doesn't count toward usage limits)
- **6 eye styles**, **8 hat types** (rarity-gated), **1% shiny chance**
- **5 stats**: DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK (0-100)

## Installation

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/matehubert/claude-buddy/main/install.sh | bash
```

Or manually:

```bash
mkdir -p ~/.claude/commands ~/.claude/skills/buddy
# Copy buddy.md → ~/.claude/commands/buddy.md
# Copy buddy.mjs, SKILL.md → ~/.claude/skills/buddy/
```

## Usage

| Command | Description |
|---------|-------------|
| `/buddy` | Hatch your buddy (first time) or check on them |
| `/buddy card` | View stat card with ASCII sprite |
| `/buddy pet` | Pet your buddy (with LLM reaction) |
| `/buddy mute` | Mute buddy reactions |
| `/buddy unmute` | Unmute buddy reactions |
| `/buddy off` | Hide buddy |

## Species Gallery

Your buddy is one of 18 species, each with a unique personality:

```
  DUCK             CAT              DRAGON           GHOST
       __         /\_/\           /\_/\_            .---.
    <(· )___     ( ✦ ✦ )        ( ×  × )>        / ° ° \
     (  ._>      =( Y )=        /|    |\         |  o  |
      `--'        /   \        d |~~~~| b        |     |
                 (_)-(_)         `----'          ^^V^V^^

  OWL             PENGUIN          TURTLE           SNAIL
    {_,_}            __            _____
   ((·,·))        /·  ·\        /(· ·)\           @@
    /)  )\       ( \__/ )      |_/---\_|        (◉  ◉)_
   / /--\ \      /|  |\         d   b          /  ___/o
   \_\  /_/     (_|  |_)                      /__(

  AXOLOTL        CAPYBARA         ROBOT            CHONK
   \\   //                       [=====]
    \\-//         .----.          |·  ·|          .------.
   (◉   ◉)      (@    @)        |[==]|        / ✦    ✦ \
    / u \         / nn \         d|  |b       |  (~~~~) |
   `-----'       `------'        |  |         \________/

  BLOB           GOOSE            OCTOPUS          RABBIT
                    __                             (\  /)
   .~~~~.        /(· )\           ,---.           ( ·· )
  ( ·  · )      ( (  ) )        (·   ·)          c(")(")
  (  __  )       \ ~~ /        ~/|/|\|\~          | Y |
   `~~~~'         `--'           | | | |          d   b

  MUSHROOM       CACTUS
    .===.          __|__
   / · · \        /  ·  \
  (  ~~~  )     --|  ·  |--
    | . |          \ __ /
    |___|          |    |
```

### Personalities

| Species | Personality |
|---------|-------------|
| Duck | Cheerful quacker who celebrates wins with honks and judges variable names |
| Goose | Agent of chaos who thrives on merge conflicts |
| Blob | Formless, chill companion who absorbs stress |
| Cat | Aloof code reviewer who secretly bats at syntax errors |
| Dragon | Fierce guardian of clean code, breathes fire at spaghetti logic |
| Octopus | Multitasking genius with tentacle-loads of unsolicited advice |
| Owl | Nocturnal sage who asks annoyingly insightful questions |
| Penguin | Tuxedo-wearing professional with dignified concern |
| Turtle | Patient mentor who favors slow, steady refactoring |
| Snail | Zen minimalist who leaves thoughtful, unhurried observations |
| Ghost | Spectral presence who haunts dead code |
| Axolotl | Regenerative optimist who believes every build can be healed |
| Capybara | The most relaxed companion -- nothing fazes them |
| Cactus | Prickly but lovable, offers sharp feedback |
| Robot | Logical companion who occasionally glitches endearingly |
| Rabbit | Hyperactive buddy who speed-reads diffs |
| Mushroom | Wry fungal sage who speaks in meandering tangents |
| Chonk | Absolute unit with maximum gravitational presence |

## Rarity System

| Tier | Probability | Stars | Stat Floor | Hats Available |
|------|-------------|-------|------------|----------------|
| Common | 60% | ★ | 5 | None |
| Uncommon | 25% | ★★ | 15 | Crown, Top Hat, Propeller |
| Rare | 10% | ★★★ | 25 | + Halo, Wizard |
| Epic | 4% | ★★★★ | 35 | + Beanie |
| Legendary | 1% | ★★★★★ | 50 | + Tiny Duck |

Additionally, any buddy has a **1% chance** of being **Shiny** (rainbow shimmer).

### Eyes

Six eye styles are randomly assigned: `·` `✦` `×` `◉` `@` `°`

## How It Works

```
User types /buddy
      │
      ▼
Claude loads buddy.md → runs buddy.mjs
      │
      ▼
FNV-1a(accountUUID + salt) → Mulberry32 PRNG
      │
      ▼
Deterministic rolls: rarity → species → eyes → hat → shiny → stats → name
      │
      ▼
buddy_react API call (OAuth from Keychain) → LLM reaction
      │
      ▼
Claude presents ASCII art + reaction via SKILL.md
```

Your buddy is generated deterministically from your Claude account UUID. The same account always produces the same species, rarity, stats, eyes, and hat.

Reactions are powered by the `buddy_react` API endpoint using your existing Claude Code OAuth credentials (read from macOS Keychain). Each call uses ~100 tokens and is tracked separately from your main usage quota.

## Token Usage

The `buddy_react` API is very lightweight:

| | Size | ~Tokens |
|---|---|---|
| Request | ~300 bytes | ~75 |
| Response | ~100 bytes | ~25 |
| **Total** | ~400 bytes | **~100/call** |

Buddy reactions use a separate `buddy_companion` query source and do not count toward your Claude Code usage limits.

## Requirements

- Claude Code v2.1.89+
- Claude Pro/Max subscription
- macOS (for Keychain credential access)
- Node.js 18+

## File Structure

```
~/.claude/
├── commands/buddy.md          # /buddy slash command
├── skills/buddy/
│   ├── SKILL.md               # Presentation instructions for Claude
│   └── buddy.mjs              # Core script (generation, rendering, API)
├── buddy.json                 # Buddy data (created on first hatch)
└── buddy-history.json         # Recent reaction history
```

## License

MIT
