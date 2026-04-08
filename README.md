# Claude Buddy

A virtual terminal pet companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Your buddy is a deterministically generated tamagotchi that lives in your terminal **and on your desktop as a rigged 3D companion with skeletal animations**, reacts to your coding activity, and keeps you company while you code.

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
- **18 species** with unique ASCII sprites, rigged 3D models, and personalities
- **5 rarity tiers**: Common (60%), Uncommon (25%), Rare (10%), Epic (4%), Legendary (1%)
- **Deterministic**: Same user always gets the same buddy (FNV-1a + Mulberry32 PRNG)
- **6 eye styles**, **8 hat types** (rarity-gated), **1% shiny chance**
- **5 stats**: DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK (0-100)

### Desktop App
- **Rigged 3D models** — all 18 species have Meshy AI auto-rigged USDZ models with skeleton, walking, and running animations driven by the behavior state machine
- **2D/3D toggle** — switch between ASCII sprite and SceneKit 3D rendering on-the-fly via menu
- **Skeletal animations** — walking animation plays during wandering/exploring, running during fast movement; lazy-loaded on first use to keep startup fast
- **Fallback procedural models** — SCN primitive models (sphere, capsule, cone, cylinder, torus) used when rigged USDZ is unavailable
- **Mood & Energy system** — mood degrades with inactivity (happy → content → bored → sad), energy 0-100 with decay; affects behavior weights
- **Behavior state machine** — idle, wandering, exploring, sitting, sleeping states with mood-weighted transitions every 30-90 seconds
- **Environment awareness** — time of day (morning/afternoon/evening/night) with lighting shifts, dark mode support, live weather via wttr.in (rain → umbrella, sunny → sunglasses)
- **Pomodoro timer** — 25/5/15 minute cycles with countdown bubble, behavior adapts (less wandering during work)
- **Mini-games** — Click Catch, Hide & Seek, Trivia via right-click menu
- **Productivity monitoring** — git HEAD watcher, clipboard monitoring, active window tracking, FSEvents file system watcher, Claude Code hook integration (session/test/build/write events)
- **Stat growth** — stats grow from real coding activity: git commits → DEBUGGING, pomodoro → PATIENCE, branch switches → CHAOS, writing code → WISDOM, petting → SNARK; daily cap of +5/stat
- **Achievements** — Pet Lover, Pet Master, Good Caretaker, Fun Times, Week Streak, Monthly Devotion
- **Streak tracking** — consecutive daily interaction counter
- **Particle effects** — hearts (pet), confetti (achievements), species-specific (water ripple, cat stars, ghost flame)
- **Species-specific tricks** — double-click triggers species trick: duck wing flap, cat jump, snail shell hide, ghost transparency
- **Mouse interaction** — proximity tracking (buddy faces mouse), hover (eye widen), fast mouse away (scared reaction), drag shake detection
- **Clipboard history** — tracks recent clipboard entries (max 20, 2KB/entry), click to re-copy
- **Photo mode** — snapshot 3D view to PNG (3D mode only)
- **Localization** — auto-detects system language (English/Hungarian), all UI strings and reactions localized
- **Menu bar integration** — species emoji + API usage percentage, click for usage popover, right-click for full context menu
- **Usage monitoring** — Claude Code API usage with 5-minute cache
- **Species brand colors** — each species has a unique accent color
- **Global hotkey** — Ctrl+Shift+B toggles buddy visibility from anywhere
- **Dark mode support** — all UI elements adapt to system appearance
- **Stability** — keyed SCNActions prevent animation piling, reaction debounce (max 1 per 8s), staged 4-phase startup, file watcher suppression, debounced data loading, lazy popover init
- **RAM optimized** — FSEvents directory-level batching, reduced animation timers, clipboard size limits, SceneKit renders on-demand only

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

## 3D Models & Rigging

All 18 species have rigged 3D models generated via [Meshy AI](https://meshy.ai):

1. **Text-to-3D** — species models generated with `meshy-6` AI model
2. **Auto-rig** — Meshy API adds humanoid skeleton (24 bones: Hips, Spine, LeftUpLeg, LeftLeg, LeftFoot, etc.)
3. **Animations** — walking and running animations generated per species
4. **USDZ conversion** — GLB models converted to USDZ via Blender for SceneKit compatibility
5. **Z-up → Y-up** — orientation corrected with pivot node rotation

The behavior state machine drives animations:
- **Idle / Sitting / Sleeping** → static pose
- **Wandering / Exploring** → walking animation
- Animations are lazy-loaded on first use (each USDZ is 15-40MB)

## Species Gallery

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

## Rarity System

| Tier | Probability | Stars | Stat Floor | Hats Available |
|------|-------------|-------|------------|----------------|
| Common | 60% | ★ | 5 | None |
| Uncommon | 25% | ★★ | 15 | Crown, Top Hat, Propeller |
| Rare | 10% | ★★★ | 25 | + Halo, Wizard |
| Epic | 4% | ★★★★ | 35 | + Beanie |
| Legendary | 1% | ★★★★★ | 50 | + Tiny Duck |

Any buddy has a **1% chance** of being **Shiny** (rainbow shimmer in terminal, metallic hue-shifting in 3D).

### Eyes

Six eye styles randomly assigned: `·` `✦` `×` `◉` `@` `°` — customizable via menu or CLI.

## Desktop App Architecture

```
desktop/
├── Package.swift                    # SPM project, macOS 13+, Swift 5.9
├── Sources/
│   ├── main.swift                   # App entry point
│   ├── AppDelegate.swift            # Main coordinator, menu bar, staged startup
│   ├── BuddyRenderProtocol.swift    # Renderer abstraction (2D/3D) + animation types
│   ├── BuddyView.swift             # ASCII 2D renderer
│   ├── Buddy3DView.swift            # SceneKit 3D renderer + rigged model loader
│   ├── SpeciesModelBuilder.swift    # Procedural fallback models (SCN primitives)
│   ├── HatModelBuilder.swift        # 3D hats + accessories
│   ├── BuddyPanel.swift            # Transparent floating window + drag + bounce
│   ├── SpeechBubbleView.swift       # Reaction text bubble + trivia buttons
│   ├── Animations.swift             # Behavior state machine, debounced reactions
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
├── Resources/
│   ├── Models/                      # Original USDZ models (text-to-3D)
│   └── Models/rigged/              # Rigged USDZ models + walk/run animations (54 files)
├── build.sh                         # Build script (copies rigged models to bundle)
├── install.sh                       # Install + LaunchAgent setup
├── rig_models.sh                    # Meshy auto-rig batch script
└── generate_models.sh               # Meshy text-to-3D batch script
```

### Key Design Decisions

- **Zero external dependencies** — SceneKit is built into macOS
- **BuddyRenderer protocol** — abstracts over 2D ASCII and 3D SceneKit renderers
- **Rigged USDZ models** — Meshy AI auto-rigged with skeleton + walking/running animations
- **Lazy animation loading** — walk/run USDZ files (15-40MB each) loaded on first behavior transition, not at startup
- **Keyed SCNActions** — all rotation/scale/move actions use `forKey:` to prevent piling up over time
- **Reaction debounce** — max 1 speech bubble per 8 seconds
- **Staged startup** — 4-phase init: UI (immediate) → input monitors (0.5s) → heavy systems (2s) → network (5s)
- **File watcher suppression** — internal writes to buddy.json skip reload cascade
- **Debounced data loading** — node process spawns coalesced, max once per second
- **Node.js auto-detection** — searches nvm, fnm, Homebrew, system paths
- **Z-up → Y-up correction** — pivot node rotation for Blender-exported USDZ models

## File Structure

```
~/.claude/
├── commands/buddy.md          # /buddy slash command
├── skills/buddy/
│   ├── buddy.mjs              # Core script (generation, rendering, reactions)
│   └── buddy-hook.mjs         # Claude Code hook script (PostToolUse/Session events)
├── buddy.json                 # Buddy data (soul, mood, energy, stats, etc.)
├── buddy-events.json          # Claude Code hook events (max 50, FIFO)
├── buddy-daily-log.json       # Daily activity log
├── buddy-pomodoro.json        # Pomodoro timer state
└── buddy-clipboard-history.json # Clipboard history (max 20 entries, 2KB/entry)

~/Applications/
└── ClaudeBuddy.app            # Desktop companion (installed via install.sh)

~/Library/LaunchAgents/
└── com.claude.buddy.plist     # Auto-start on login
```

## License

MIT
