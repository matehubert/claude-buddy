# Claude Buddy

A virtual terminal pet companion for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Your buddy is a deterministically generated tamagotchi that lives in your terminal **and on your desktop as a 3D SceneKit companion**, reacts to your coding activity via the Anthropic API, and keeps you company while you code.

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
- **LLM-powered reactions**: Your buddy reacts to your coding via the `buddy_react` API (~100 tokens/call, doesn't count toward usage limits)
- **6 eye styles**, **8 hat types** (rarity-gated), **1% shiny chance**
- **5 stats**: DEBUGGING, PATIENCE, CHAOS, WISDOM, SNARK (0-100)

### Desktop App (2.0)
- **3D SceneKit rendering** — each species built from SCN primitives (sphere, capsule, cone, cylinder, torus) with PBR materials, orthographic camera, transparent window
- **Mood & Energy system** — mood degrades with inactivity (happy → content → bored → sad), energy 0-100 with decay; affects behavior weights and facial expressions
- **Environment awareness** — time of day detection (morning/afternoon/evening/night) with lighting shifts, dark mode support, live weather via wttr.in (rain → umbrella accessory, sunny → sunglasses)
- **Pomodoro timer** — 25/5/15 minute cycles with countdown bubble, buddy behavior adapts (less wandering during work, more during breaks)
- **Mini-games** — Click Catch, Hide & Seek, Trivia via right-click menu
- **Productivity monitoring** — git HEAD watcher (commit/branch switch/conflict reactions), clipboard monitoring (large paste/code copy detection), active window tracking (coding/browser/other app detection), file system watcher (FSEvents-based change detection with intensity levels), Claude Code hook integration (session/test/build/write events via buddy-hook.mjs)
- **Achievements** — Pet Lover, Pet Master, Good Caretaker, Fun Times, Week Streak, Monthly Devotion
- **Streak tracking** — consecutive daily interaction counter
- **Particle effects** — hearts (pet), confetti (achievements), species-specific (water ripple for duck, cat stars, ghost flame, slime trail)
- **Accessories** — umbrella, sunglasses, scarf, wings (with flap animation)
- **3D hats** — crown (with gems), top hat (with red band), propeller (spinning), halo (glowing + bob), wizard (with stars), beanie (with pom-pom), tiny duck
- **Shiny variants** — metallic PBR + hue-shifting emission animation
- **Species-specific tricks** — double-click: duck quacks + wing flap, cat jumps + stars, snail hides in shell, ghost goes transparent + BOO!, default spin
- **Mouse interaction** — proximity tracking (buddy faces mouse), hover (eye widen), fast mouse away (scared reaction), drag shake detection (wobble)
- **Photo mode** — snapshot 3D view to PNG
- **Localization** — auto-detects system language (English/Hungarian), all UI strings and buddy reactions localized, language passed to buddy_react API for AI-generated responses in the correct language
- **2D/3D toggle** — switch between ASCII sprite and SceneKit 3D rendering on-the-fly via menu, preference persisted
- **Species reroll** — hatch a brand new egg at any time; resets progress, mood, energy, and streak but keeps settings (language, muted state)
- **Center Buddy** — bring buddy back to screen center if it wanders off
- **Menu bar integration** — species emoji + usage percentage, click for usage popover, right-click for full context menu
- **Usage monitoring** — Claude Code API usage with 5-minute cache, sync button for instant refresh

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
# Copy buddy.mjs, SKILL.md → ~/.claude/skills/buddy/
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
| `/buddy pet` | Pet your buddy (with LLM reaction) |
| `/buddy mute` | Mute buddy reactions |
| `/buddy unmute` | Unmute buddy reactions |
| `/buddy off` | Hide buddy |

### CLI Commands (via buddy.mjs)

| Command | Description |
|---------|-------------|
| `node buddy.mjs mood` | Show mood emoji + energy bar |
| `node buddy.mjs feed` | Feed buddy (+15 energy, improves mood) |
| `node buddy.mjs pomodoro start` | Start 25-minute focus timer |
| `node buddy.mjs pomodoro stop` | Stop pomodoro |
| `node buddy.mjs pomodoro status` | Check pomodoro status |
| `node buddy.mjs game` | Random trivia question |
| `node buddy.mjs streak` | Show current day streak |
| `node buddy.mjs achievements` | List unlocked achievements |
| `node buddy.mjs eyes <style>` | Change eye style |
| `node buddy.mjs hat <type>` | Change hat |
| `node buddy.mjs reroll` | Hatch a brand new buddy (resets progress) |

### Desktop App Menu

Right-click the buddy or the menu bar icon:

- **Pet / Feed** — interact with your buddy
- **Pomodoro** — start/stop focus timer
- **Games** — Click Catch, Hide & Seek, Trivia
- **Customize** — Eyes, Hat, Accessories, Language, 2D/3D toggle
- **Hatch New Egg** — reroll species (confirmation dialog, resets progress)
- **Center Buddy** — snap buddy back to screen center
- **Take Photo** — save 3D snapshot as PNG (3D mode only)
- **View Card** — show stat card in a panel
- **Usage** — Claude Code API usage popover

## Mood & Energy

Your buddy has emotional state that evolves over time:

| Mood | Trigger | Behavior |
|------|---------|----------|
| Excited | High energy + interaction | Lots of wandering and exploring |
| Happy | Pet/play/feed | Active, balanced behavior |
| Content | Default state | Normal behavior weights |
| Bored | 3+ hours inactivity | Mostly idle and sitting |
| Sad | 6+ hours inactivity or low energy | Minimal movement, droopy eyes |
| Grumpy | — | Irritable expressions |

**Energy** (0-100): -1 every 10 minutes idle, +5 pet, +15 feed, +10 play. Low energy (<20) forces sad mood.

## Mini-Games

Three games accessible via right-click → Games menu:

| Game | How to Play | Scoring |
|------|-------------|---------|
| **Click Catch** | Buddy says "Wait for it..." then "GO!" — click as fast as possible | Points based on reaction time; "Too slow!" if >2s |
| **Hide & Seek** | Buddy teleports to a random screen position — find and click | Bonus points for speed; times out after a few seconds |
| **Trivia** | Programming trivia question with 3 clickable answer buttons in speech bubble | 3 questions per round; score tracked |

Games award +10 energy and count toward the "Fun Times" achievement.

## Environment Awareness

| Feature | How It Works |
|---------|-------------|
| Time of day | Detected every 5 min; affects lighting (warm morning, neutral afternoon, orange evening, blue night) and behavior |
| Dark mode | Listens to `AppleInterfaceThemeChangedNotification` |
| Weather | Fetches `wttr.in/?format=%C\|%t` every 30 min; rain → umbrella, sunny → sunglasses |
| Active window | `NSWorkspace.didActivateApplicationNotification`; categorizes apps as coding (VS Code, Xcode, Terminal, iTerm, Warp, Claude Code), browser (Safari, Chrome, Arc), or other; 30s debounce |
| File system | FSEvents-based recursive directory watcher; filters `.git/`, `.build/`, `node_modules/`; 2s batching with intensity levels (10+ = coding storm, 5+ = lots of changes, 1+ = file activity); 30s debounce |
| Claude Code hooks | `buddy-hook.mjs` processes PostToolUse/SessionStart/Stop events → `buddy-events.json`; categorizes into session_start/end, running_tests, building, running_command, writing_code; 20s debounce |
| Screen edge | Buddy detects screen boundaries with bounce physics |

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

### 3D Models

Each species is built entirely from SceneKit primitives (`SCNSphere`, `SCNCapsule`, `SCNCone`, `SCNCylinder`, `SCNTorus`, `SCNBox`) with PBR materials (roughness 0.7, metalness 0.1 for a toy/matt look):

```
 3D Species Construction (SCN Primitives)
 ─────────────────────────────────────────

 DUCK                CAT                 SNAIL               GOOSE
 ┌─sphere─┐         ┌─sphere─┐          ┌─sphere─┐         ┌─sphere─┐
 │  head   │        │  head   │ ◄cone   │  shell  │←torus  │  head   │
 └────┬────┘        └──┬──┬──┘  ears    └────┬────┘spiral  └────┬────┘
 ┌────┴────┐        ┌──┴──┴──┐          ┌────┴────┐        ┌────┴────┐
 │ capsule │◄cone   │capsule │          │ capsule │        │cylinder │
 │  body   │ beak   │  body  │←tail     │  body   │←stalks │  neck   │
 └──┬──┬──┘        └──┬──┬──┘          └─────────┘        └────┬────┘
   cyl  cyl           sph sph                              ┌────┴────┐
   feet feet          paws                                 │ capsule │
                                                           │  body   │
                                                           └──┬──┬──┘
                                                             cyl  cyl

 DRAGON              GHOST               OCTOPUS             OWL
 ┌─sphere─┐         ┌─────────┐         ┌─sphere─┐         ┌─sphere─┐
 │  head   │←horns  │ capsule │ ◄0.5α   │  head   │        │  head   │←tufts
 └────┬────┘        │  body   │         └────┬────┘        └────┬────┘
 ┌────┴────┐        └────┬────┘         ╔════╧════╗        ┌────┴────┐
 │ capsule │←wings     cone waves      ║8×capsule ║        │ capsule │
 │  body   │                            ║tentacles║        │  body   │
 └────┬────┘                            ╚═════════╝        └─────────┘
    tail

 PENGUIN             TURTLE              AXOLOTL             CAPYBARA
 ┌─sphere─┐         ┌─sphere─┐         ┌─sphere─┐←gills    ┌─sphere─┐
 │  head   │        │  head   │         │  head   │ (6×)    │  head   │←ears
 └────┬────┘        └────┬────┘         └────┬────┘         └────┬────┘
 ┌────┴────┐        ┌────┴────┐         ┌────┴────┐         ┌────┴────┐
 │ capsule │←flips  │ sphere  │←legs    │ capsule │←tail    │ capsule │←legs
 │  body   │        │  shell  │ (4×)    │  body   │ +legs   │  body   │ (4×)
 └──┬──┬──┘        └─────────┘         └─────────┘         └─────────┘
   cyl  cyl
   feet

 CACTUS              ROBOT               RABBIT              MUSHROOM
    ┌──┐             ┌antenna┐           ┌─capsule─┐        ┌─sphere─┐
    │sph│ flower     │  sph   │          │  ears    │ (2×)   │   cap  │←spots
    └──┘             └───┬────┘          └────┬────┘        └────┬────┘
 ┌──────────┐        ┌───┴────┐          ┌────┴────┐        ┌────┴────┐
 │ cylinder │←arms   │  box   │←arms     │ sphere  │        │cylinder │
 │   body   │(2×cap) │  head  │(2×cap)   │  head   │        │  stem   │
 └──────────┘        ┌───┴────┐          └────┬────┘        └─────────┘
                     │  box   │←legs     ┌────┴────┐
                     │  body  │(2×cap)   │ capsule │←tail
                     └────────┘          │  body   │
                                         └─────────┘

 BLOB                CHONK
 ┌──────────┐       ┌─sphere─┐
 │  sphere  │       │  head   │←ears
 │  (body)  │←mouth └────┬────┘
 │ scaled   │       ┌────┴────┐
 └──────────┘       │ sphere  │←belly
                    │  body   │ highlight
                    └────┬────┘
                        tail
```

**Shiny variants** add metalness 0.5 + hue-shifting emission animation cycling through the color spectrum.

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

Additionally, any buddy has a **1% chance** of being **Shiny** (rainbow shimmer in terminal, metallic PBR + hue-shifting emission in 3D).

### Eyes

Six eye styles are randomly assigned: `·` `✦` `×` `◉` `@` `°`

Eyes can be customized via the desktop app menu or `node buddy.mjs eyes <style>`.

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

Reactions are powered by the `buddy_react` API endpoint using your existing Claude Code OAuth credentials (read from macOS Keychain or `~/.claude/.credentials.json`). Each call uses ~100 tokens and is tracked separately from your main usage quota.

## Desktop App Architecture

```
desktop/
├── Package.swift                    # SPM project, macOS 13+, Swift 5.9
├── Sources/
│   ├── main.swift                   # App entry point
│   ├── AppDelegate.swift            # Main coordinator, menu bar, system wiring
│   ├── BuddyRenderProtocol.swift    # Renderer abstraction (2D/3D)
│   ├── BuddyView.swift             # ASCII 2D renderer (BuddyRenderer conformance)
│   ├── Buddy3DView.swift            # SceneKit 3D renderer
│   ├── SpeciesModelBuilder.swift    # 18 species as SCN primitives
│   ├── HatModelBuilder.swift        # 3D hats + accessories
│   ├── BuddyPanel.swift            # Transparent floating window + drag
│   ├── SpeechBubbleView.swift       # Reaction text bubble
│   ├── Animations.swift             # Behavior state machine + all animations
│   ├── BuddyData.swift             # Soul/bones persistence + file watcher
│   ├── BuddyLocalization.swift      # EN/HU localized strings
│   ├── MoodEnergySystem.swift       # Mood/energy/streak/achievements
│   ├── EnvironmentAwareness.swift   # Time of day, dark mode, weather
│   ├── PomodoroTimer.swift          # 25/5/15 focus timer
│   ├── MiniGames.swift             # Click Catch, Hide & Seek, Trivia
│   ├── ProductivityMonitor.swift    # Git, clipboard, active window, FSEvents, Claude Code hook monitors
│   ├── UsageAPI.swift              # Claude Code usage API client
│   ├── UsageView.swift             # Usage popover UI
│   └── CredentialManager.swift      # OAuth credential management
├── build.sh                         # Build script
├── install.sh                       # Install + LaunchAgent setup
└── Resources/                       # App icon
```

### Key Design Decisions

- **Zero external dependencies** — SceneKit is built into macOS
- **BuddyRenderer protocol** — abstracts over 2D ASCII and 3D SceneKit renderers; the app can switch between them
- **Primitive-based 3D models** — no external model files; all geometry built from `SCNSphere`, `SCNCapsule`, `SCNCone`, `SCNCylinder`, `SCNTorus`
- **PBR materials** — roughness 0.7, metalness 0.1 for a matt/toy look; shiny variants use metalness 0.5
- **Transparent window** — `SCNView.backgroundColor = .clear` + `scene.background.contents = NSColor.clear`
- **Orthographic camera** — `orthographicScale = 3.0` for flat, cute perspective
- **Backward-compatible persistence** — new fields in `buddy.json` are optional, old files keep working
- **Node.js auto-detection** — LaunchAgent apps don't inherit shell PATH, so the app searches `~/.nvm`, `~/.local/share/fnm`, `/opt/homebrew/bin`, `/usr/local/bin` automatically

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
- macOS 13+ (Ventura) for the desktop app
- Node.js 18+
- Swift 5.9+ / Xcode Command Line Tools (for building the desktop app)

## File Structure

```
~/.claude/
├── commands/buddy.md          # /buddy slash command
├── skills/buddy/
│   ├── SKILL.md               # Presentation instructions for Claude
│   ├── buddy.mjs              # Core script (generation, rendering, API)
│   └── buddy-hook.mjs         # Claude Code hook script (PostToolUse/Session events)
├── buddy.json                 # Buddy data (soul, mood, energy, language, etc.)
├── buddy-history.json         # Recent reaction history
├── buddy-events.json          # Claude Code hook events (max 50, FIFO)
└── buddy-pomodoro.json        # Pomodoro timer state

~/Applications/
└── ClaudeBuddy.app            # Desktop companion (installed via install.sh)

~/Library/LaunchAgents/
└── com.claude.buddy.plist     # Auto-start on login
```

## License

MIT
