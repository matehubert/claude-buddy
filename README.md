# Claude Buddy

A virtual terminal pet companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Your buddy is a deterministically generated tamagotchi that lives in your terminal **and on your desktop as a 3D SceneKit companion**, reacts to your coding activity, and keeps you company while you code.

## Example

```
╔═════════════════════════════════════════╗
║               Pike                      ║
║  ◉    .--.    ★ Common Snail            ║
║   \  ( @ )                              ║
║    \_`--´     Hatched: 2026-04-03       ║
║   ~~~~~~~                               ║
║                                         ║
║  DEBUGGING  [████░░░░░░░░░░░░]  28      ║
║  PATIENCE   [█████░░░░░░░░░░░]  33      ║
║  CHAOS      [░░░░░░░░░░░░░░░░]   1      ║
║  WISDOM     [██████░░░░░░░░░░]  39      ║
║  SNARK      [█████████████░░░]  81      ║
╚═════════════════════════════════════════╝
```

## Features

### Core
- **18 species** with unique ASCII sprites, 3D models, and personalities
- **5 rarity tiers**: Common (60%), Uncommon (25%), Rare (10%), Epic (4%), Legendary (1%)
- **Deterministic**: Same user always gets the same buddy (FNV-1a + Mulberry32 PRNG)
- **Static reactions**: Context-aware reactions for coding events (commits, sessions, tests, builds) using localized string pools
- **6 eye styles**, **8 hat types** (rarity-gated), **1% shiny chance**
- **5 stats**: DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK (0-100)

### Desktop App
- **3D SceneKit rendering** — each species built from SCN primitives (sphere, capsule, cone, cylinder, torus) with PBR materials, orthographic camera, transparent window
- **2D/3D toggle** — switch between ASCII sprite and SceneKit 3D rendering on-the-fly via menu
- **Mood & Energy system** — mood degrades with inactivity (happy → content → bored → sad), energy 0-100 with decay; affects behavior weights and facial expressions
- **Environment awareness** — time of day detection (morning/afternoon/evening/night) with lighting shifts, dark mode support, live weather via wttr.in (rain → umbrella accessory, sunny → sunglasses)
- **Pomodoro timer** — 25/5/15 minute cycles with countdown bubble, buddy behavior adapts (less wandering during work, more during breaks)
- **Mini-games** — Click Catch, Hide & Seek, Trivia via right-click menu
- **Productivity monitoring** — git HEAD watcher, clipboard monitoring, active window tracking, FSEvents file system watcher, Claude Code hook integration (session/test/build/write events via buddy-hook.mjs)
- **Stat growth** — stats grow from real coding activity: git commits → DEBUGGING, pomodoro → PATIENCE, branch switches → CHAOS, writing code → WISDOM, petting → SNARK; daily cap of +5/stat
- **Achievements** — Pet Lover, Pet Master, Good Caretaker, Fun Times, Week Streak, Monthly Devotion
- **Streak tracking** — consecutive daily interaction counter
- **Particle effects** — hearts (pet), confetti (achievements), species-specific (water ripple for duck, cat stars, ghost flame)
- **Accessories** — umbrella, sunglasses, scarf, wings (with flap animation)
- **3D hats** — crown, top hat, propeller (spinning), halo (glowing), wizard, beanie, tiny duck
- **Shiny variants** — metallic PBR + hue-shifting emission animation
- **Species-specific tricks** — double-click: duck quacks + wing flap, cat jumps + stars, snail hides in shell, ghost goes transparent
- **Mouse interaction** — proximity tracking (buddy faces mouse), hover (eye widen), fast mouse away (scared reaction), drag shake detection
- **Clipboard history** — tracks recent clipboard entries, click to re-copy from history popover
- **Photo mode** — snapshot 3D view to PNG (3D mode only)
- **Localization** — auto-detects system language (English/Hungarian), all UI strings and reactions localized
- **Menu bar integration** — species emoji + API usage percentage, click for usage popover, right-click for full context menu
- **Usage monitoring** — Claude Code API usage with 5-minute cache
- **Species brand colors** — each species has a unique accent color (duck gold, dragon red, octopus purple, etc.)
- **Global hotkey** — Ctrl+Shift+B toggles buddy visibility from anywhere
- **Staged startup** — 4-phase initialization prevents UI freezes (UI → input → monitors → network)
- **Dark mode support** — all UI elements (chat bubbles, popovers) adapt to system appearance
- **RAM optimized** — lazy popover init, FSEvents directory-level batching, reduced animation timers, clipboard size limits

## Installation

### Terminal Companion (slash command)

One-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/matehubert/claude-buddy/main/install.sh | bash
```

Or manually:

```bash
mkdir -p ~/.claude/commands ~/.claude/skills/buddy
# Copy buddy.md → ~/.claude/commands/buddy.md
# Copy buddy.mjs → ~/.claude/skills/buddy/
```

### Desktop App

```bash
cd desktop
bash install.sh
```

This builds the Swift app, installs to `~/Applications/ClaudeBuddy.app`, and sets up a LaunchAgent for auto-start on login.

**Requirements:**
- macOS 13+ (Ventura)
- Swift 5.9+ / Xcode Command Line Tools
- Node.js 18+ (auto-detected from nvm, fnm, Homebrew, or system install)
- No external dependencies (SceneKit is a built-in macOS framework)

## Usage

### Terminal Commands

| Command | Description |
|---------|-------------|
| `/buddy` | Hatch your buddy (first time) or check on them |
| `/buddy card` | View stat card with ASCII sprite |
| `/buddy pet` | Pet your buddy |
| `/buddy feed` | Feed buddy (+15 energy) |
| `/buddy mood` | Show mood emoji + energy bar |
| `/buddy game` | Random trivia question |
| `/buddy streak` | Show current day streak |
| `/buddy achievements` | List unlocked achievements |
| `/buddy pomodoro start/stop` | Pomodoro focus timer |
| `/buddy eyes <style>` | Change eye style |
| `/buddy hat <type>` | Change hat |
| `/buddy reroll` | Hatch a brand new buddy (resets progress) |
| `/buddy mute` / `unmute` | Mute/unmute reactions |
| `/buddy off` | Hide buddy |

### Desktop App Menu

Right-click the buddy or the menu bar icon:

- **Pet / Feed** — interact with your buddy
- **Pomodoro** — start/stop focus timer
- **Games** — Click Catch, Hide & Seek, Trivia
- **Clipboard History** — browse and re-copy recent clipboard entries
- **Customize** — Eyes, Hat, Accessories, Language, 2D/3D toggle
- **Hatch New Egg** — reroll species (confirmation dialog, resets progress)
- **Center Buddy** — snap buddy back to screen center
- **Take Photo** — save 3D snapshot as PNG (3D mode only)
- **View Card** — show stat card in a panel
- **Usage** — Claude Code API usage popover

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+Shift+B | Toggle buddy visibility (global hotkey) |

## Mood & Energy

Your buddy has emotional state that evolves over time:

| Mood | Trigger | Behavior |
|------|---------|----------|
| Excited | High energy + interaction | Lots of wandering and exploring |
| Happy | Pet/play/feed | Active, balanced behavior |
| Content | Default state | Normal behavior weights |
| Bored | 3+ hours inactivity | Mostly idle and sitting |
| Sad | 6+ hours inactivity or low energy | Minimal movement |
| Grumpy | — | Irritable expressions |

**Energy** (0-100): -1 every 10 minutes idle, +5 pet, +15 feed, +10 play. Low energy (<20) forces sad mood.

## Stat Growth

Stats grow from real coding activity, making each buddy unique to how you work.

| Activity | Stat | Amount |
|----------|------|--------|
| Git commit | DEBUGGING | +1 |
| Merge conflict | DEBUGGING | +2 |
| Branch switch | CHAOS | +1 |
| Writing code (Claude) | WISDOM | +1 |
| Pomodoro complete | PATIENCE | +2 |
| Coding storm (10+ files) | PATIENCE | +2 |
| Pet buddy | SNARK | +1 |
| Game complete | CHAOS | +1 |
| 7-day streak | WISDOM | +3 |

Daily cap: +5 per stat per day (resets at midnight).

## Mini-Games

| Game | How to Play | Scoring |
|------|-------------|---------|
| **Click Catch** | Wait for "GO!" then click fast | Points based on reaction time |
| **Hide & Seek** | Buddy teleports — find and click | Bonus for speed |
| **Trivia** | Programming trivia, 3 answer buttons | 3 questions per round |

## Environment Awareness

| Feature | How It Works |
|---------|-------------|
| Time of day | Detected every 5 min; affects lighting and behavior |
| Dark mode | Listens to system appearance changes |
| Weather | Fetches wttr.in every 30 min; rain → umbrella, sunny → sunglasses |
| Active window | Categorizes apps as coding/browser/other |
| File system | FSEvents directory-level watcher with intensity detection |
| Claude Code hooks | PostToolUse/SessionStart/Stop events via buddy-hook.mjs |
| Screen edge | Boundary detection with bounce physics |

## Species Gallery

Your buddy is one of 18 species, each with a unique personality:

```
  DUCK             CAT              DRAGON           GHOST
    __            /\_/\          /^\  /^\          .----.
  <(· )___      ( ·   ·)      <  ·  ·  >       / ·  · \
   (  ._>       (  ω  )       (   ~~   )       |      |
    `--´        (")_(")        `-vvvv-´         ~`~``~`~

  OWL            PENGUIN          TURTLE           SNAIL
   /\  /\       .---.            _,--._
  ((·)(·))      (·>·)          ( ·  · )        ·    .--.
  (  ><  )     /(   )\        /[______]\        \  ( @ )
   `----´       `---´          ``    ``          \_`--´
                                               ~~~~~~~

  AXOLOTL       CAPYBARA         ROBOT            CHONK
}~(______)~{   n______n         .[||].          /\    /\
}~(· .. ·)~{  ( ·    · )      [ ·  · ]        ( ·    · )
  ( .--. )    (   oo   )      [ ==== ]        (   ..   )
  (_/  \_)     `------´        `------´         `------´

  BLOB          GOOSE           OCTOPUS          RABBIT
   .----.        (·>              .----.         (\__/)
  ( ·  · )       ||            ( ·  · )        ( ·  · )
  (      )     _(__)_          (______)       =(  ..  )=
   `----´       ^^^^           /\/\/\/\        (")__(")

  MUSHROOM      CACTUS
 .-o-OO-o-.   n  ____  n
(__________)  | |·  ·| |
   |·  ·|     |_|    |_|
   |____|       |    |
```

### Personalities

| Species | Personality |
|---------|-------------|
| Duck | Cheerful quacker who celebrates wins with honks |
| Goose | Agent of chaos who thrives on merge conflicts |
| Blob | Formless, chill companion who absorbs stress |
| Cat | Aloof code reviewer who secretly bats at syntax errors |
| Dragon | Fierce guardian of clean code |
| Octopus | Multitasking genius with tentacle-loads of advice |
| Owl | Nocturnal sage who asks insightful questions |
| Penguin | Tuxedo-wearing professional with dignified concern |
| Turtle | Patient mentor who favors slow, steady refactoring |
| Snail | Zen minimalist who leaves thoughtful observations |
| Ghost | Spectral presence who haunts dead code |
| Axolotl | Regenerative optimist who believes every build can be healed |
| Capybara | The most relaxed companion — nothing fazes them |
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

Any buddy has a **1% chance** of being **Shiny** (rainbow shimmer in terminal, metallic PBR + hue-shifting in 3D).

### Eyes

Six eye styles randomly assigned: `·` `✦` `×` `◉` `@` `°` — customizable via menu or CLI.

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
Claude presents ASCII art + reaction
```

Your buddy is generated deterministically from your Claude account UUID. The same account always produces the same species, rarity, stats, eyes, and hat.

## Desktop App Architecture

```
desktop/
├── Package.swift                    # SPM project, macOS 13+, Swift 5.9
├── Sources/
│   ├── main.swift                   # App entry point
│   ├── AppDelegate.swift            # Main coordinator, menu bar, staged startup
│   ├── BuddyRenderProtocol.swift    # Renderer abstraction (2D/3D)
│   ├── BuddyView.swift             # ASCII 2D renderer
│   ├── Buddy3DView.swift            # SceneKit 3D renderer
│   ├── SpeciesModelBuilder.swift    # 18 species as SCN primitives
│   ├── HatModelBuilder.swift        # 3D hats + accessories
│   ├── BuddyPanel.swift            # Transparent floating window + drag
│   ├── SpeechBubbleView.swift       # Reaction text bubble
│   ├── Animations.swift             # Behavior state machine + animations
│   ├── BuddyData.swift             # Soul/bones persistence, debounced file watcher
│   ├── BuddyLocalization.swift      # EN/HU localized strings
│   ├── MoodEnergySystem.swift       # Mood/energy/streak/achievements
│   ├── EnvironmentAwareness.swift   # Time of day, dark mode, weather
│   ├── PomodoroTimer.swift          # 25/5/15 focus timer
│   ├── MiniGames.swift             # Click Catch, Hide & Seek, Trivia
│   ├── ProductivityMonitor.swift    # Git, clipboard, window, FSEvents, hook monitors
│   ├── ClipboardHistoryView.swift   # Clipboard history popover
│   ├── UsageAPI.swift              # Claude Code usage API client
│   ├── UsageView.swift             # Usage popover UI
│   └── CredentialManager.swift      # OAuth credential management
├── Resources/Models/                # USDZ 3D models (optional, per-species)
├── build.sh                         # Build script
└── install.sh                       # Install + LaunchAgent setup
```

### Key Design Decisions

- **Zero external dependencies** — SceneKit is built into macOS
- **BuddyRenderer protocol** — abstracts over 2D ASCII and 3D SceneKit renderers
- **Staged startup** — 4-phase init: UI (immediate) → input monitors (0.5s) → heavy systems (2s) → network (5s)
- **File watcher suppression** — internal writes to buddy.json skip reload cascade
- **Debounced data loading** — node process spawns coalesced, max once per second
- **Pipe read-before-wait** — all Process pipe reads happen before waitUntilExit() to prevent deadlocks
- **Lazy popovers** — usage and clipboard popovers created on first open, not at startup
- **Node.js auto-detection** — searches nvm, fnm, Homebrew, system paths (LaunchAgent apps don't inherit shell PATH)
- **Backward-compatible persistence** — new fields in buddy.json are optional

## File Structure

```
~/.claude/
├── commands/buddy.md          # /buddy slash command
├── skills/buddy/
│   ├── buddy.mjs              # Core script (generation, rendering, reactions)
│   └── buddy-hook.mjs         # Claude Code hook script (PostToolUse/Session events)
├── buddy.json                 # Buddy data (soul, mood, energy, stats, etc.)
├── buddy-history.json         # Recent reaction history
├── buddy-events.json          # Claude Code hook events (max 50, FIFO)
├── buddy-daily-log.json       # Daily activity log
├── buddy-pomodoro.json        # Pomodoro timer state
├── buddy-clipboard-history.json # Clipboard history (max 20 entries, 2KB/entry)
└── buddy-config.json          # Desktop app config

~/Applications/
└── ClaudeBuddy.app            # Desktop companion (installed via install.sh)

~/Library/LaunchAgents/
└── com.claude.buddy.plist     # Auto-start on login
```

## License

MIT
