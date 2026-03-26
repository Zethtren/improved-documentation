# houston-cv: The Vision

> A terminal operating system disguised as a CV. Not a website with terminal styling — an actual interactive terminal experience with a CRT boot sequence, a working shell, dynamic data from a graph database, a personal life OS dashboard, local AI integration, and more easter eggs than a Nethack dungeon. All in Catppuccin.

---

## Table of Contents

1. [Architecture](#1-architecture)
2. [The Boot Sequence](#2-the-boot-sequence)
3. [The CV (Layer 1 — What Recruiters See)](#3-the-cv)
4. [Interactive Terminal (Layer 2 — Curious Visitors)](#4-interactive-terminal)
5. [Deep Exploration (Layer 3 — Power Users)](#5-deep-exploration)
6. [Visual Effects (Layer 4 — Opt-In Polish)](#6-visual-effects)
7. [Sound Design (Layer 5 — Atmospheric)](#7-sound-design)
8. [SurrealDB Data Model](#8-surrealdb-data-model)
9. [The Dashboard — Personal Life OS](#9-the-dashboard)
10. [Local AI / ML Integration](#10-local-ai--ml-integration)
11. [GKE Deployment](#11-gke-deployment)
12. [PWA — Install houston](#12-pwa)
13. [Accessibility](#13-accessibility)
14. [Catppuccin Ecosystem](#14-catppuccin-ecosystem)
15. [Priority Roadmap](#15-priority-roadmap)

---

## 1. Architecture

### Repo Structure

```
houston-cv/
├── apps/
│   ├── leptos-cv/              # Public-facing terminal CV (Rust/WASM)
│   │   ├── Cargo.toml
│   │   ├── Trunk.toml
│   │   ├── src/main.rs
│   │   ├── style.css
│   │   └── index.html
│   ├── surrealdb/              # Database schemas, seed data, migrations
│   └── phoenix-dashboard/      # Personal Life OS (Elixir/Phoenix LiveView)
├── k8s/
│   ├── base/                   # Kustomize base manifests
│   └── overlays/
│       ├── dev/
│       └── prod/
├── docs/
│   └── vision.md               # This file
└── .gitignore
```

### Critical Decision: Leptos SSR + Islands

The SurrealDB Rust SDK **cannot compile to `wasm32-unknown-unknown`** (depends on `ring` and `psm`). This kills the "CSR talks directly to SurrealDB" path.

**Recommended architecture: Leptos SSR with Islands mode** via `cargo-leptos` + Axum.

- 95% of the site is server-rendered HTML (fast first paint, SEO-friendly, crawlable by Google/LinkedIn/AI search)
- Only the theme switcher and interactive terminal emulator are WASM islands (~50-166KB compressed vs ~350KB+ for full SPA)
- Server functions query SurrealDB via the native Rust SDK — DB never exposed to the internet
- SurrealDB stays `ClusterIP`-only inside the GKE cluster

**Islands binary size impact:**

| Scenario | WASM Size (uncompressed) |
|----------|--------------------------|
| Static app, no islands | 24 KB |
| Single interactive island | 166 KB |
| Full SPA (non-islands) | 274-355 KB |

**Build tooling change:** Trunk → `cargo-leptos`. Features split: `ssr` for server, `hydrate`/`islands` for client.

### Service Architecture

```
                      Internet
                         │
                    ┌────┴─────┐
                    │ GKE L7   │
                    │ Ingress  │
                    └────┬─────┘
                    ┌────┴─────┐
         ┌──────── │  Routes   │ ────────┐
         │         └───────────┘         │
         ▼                               ▼
  zethtren.xyz                  admin.zethtren.xyz
  ┌──────────────┐              ┌──────────────────┐
  │  Leptos SSR  │              │ Phoenix LiveView  │
  │  (Axum)      │              │ (Admin/Life OS)   │
  └──────┬───────┘              └────────┬──────────┘
         │                               │
         └───────────┐  ┌────────────────┘
                     ▼  ▼
              ┌──────────────┐
              │  SurrealDB   │
              │ (ClusterIP)  │
              │ StatefulSet  │
              └──────────────┘
                     │
              ┌──────┴───────┐
              │  Ollama /    │
              │  Local AI    │
              │  (GPU pod)   │
              └──────────────┘
```

---

## 2. The Boot Sequence

First visit only. Skippable with ESC. Respects `prefers-reduced-motion`. Stored in `localStorage` so it never replays.

### Phase 0: CRT Power-On (0-1.5s)
- Black screen
- Bright horizontal line appears at vertical center (CSS `clip-path: inset(49.9% 0)` animation)
- Line expands vertically to full screen
- Brief white flash/bloom that fades
- Scanlines fade in

### Phase 1: BIOS POST (1.5s-3s)
```
Award BIOS v6.66, An Energy Star Ally
Copyright (C) 1984-2026, Award Software, Inc.

Houston K. Bova Custom PC Rev 1.0
Main Processor: Rust 1.77.0 (WASM)
Memory Test: 1048576K OK

Detecting Primary Master... [leptos-cv v0.1.0]
Detecting Primary Slave... [catppuccin-theme OK]
```
Each line appears with 50-100ms delay. Memory counter rapidly counts up.

### Phase 2: GRUB Menu — THE Theme Picker (3s-5s)
```
GNU GRUB version 2.06

*Catppuccin Mocha (default)
 Catppuccin Macchiato
 Catppuccin Frappe
 Catppuccin Latte
 ──────────────────
 Green Phosphor (1982)
 Amber Phosphor (1987)
 ──────────────────
 Advanced options for houston-cv

The selected entry will boot in 3 seconds...
```
- Arrow keys / mouse to select flavor — **this is a functional theme picker disguised as GRUB**
- Countdown timer auto-boots into the default (Mocha)
- CRT phosphor themes add retro modes alongside the four Catppuccin flavors:
  - P1 Green: `#33ff33` on `#0a0a0a` — classic VT100 hacker terminal
  - P3 Amber: `#ffb000` on `#0a0800` — IBM 5151 office terminal
  - All phosphor themes exceed WCAG AAA contrast (12:1 to 21:1)

### Phase 3: systemd Boot Messages (5s-7s)
```
[  OK  ] Started leptos-cv.service — CV Web Application
[  OK  ] Reached target catppuccin-mocha.target — Theme Engine
[  OK  ] Started wasm-bindgen.service — WASM Bindings
[  OK  ] Started surrealdb.service — Graph Database
[  OK  ] Reached target network-online.target — Network Ready
[  OK  ] Started houston-shell.service — Interactive Shell
```
Messages scroll quickly (30-50ms per line). `[ OK ]` in green, service names in white, descriptions dimmed.

**Key insight:** During the boot sequence, the WASM module is genuinely loading. The BIOS POST plays while WASM downloads. The GRUB menu appears while it compiles. The systemd messages scroll while Leptos hydrates. The animation is a functional loading indicator, not just decoration.

### Phase 4: Login + MOTD (7s-10s)
```
houston-cv login: houston
Password: ********

Last login: Tue Mar 25 14:32:17 2026 from 192.168.1.100

 _________________________________
/ Mass assignments are foot guns. \
\ — Houston, probably             /
 ---------------------------------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```
- "Last login" uses actual timestamp from `localStorage`
- MOTD is a `fortune | cowsay` that changes daily (based on `day_of_year % quotes.length`)
- Then the existing fastfetch display renders
- Shell prompt appears with blinking cursor
- Site is ready

### CSS Techniques

- **Power-on line**: `clip-path: inset()` animated from `inset(50% 0)` to `inset(0 0)` — GPU-composited, smooth
- **Phosphor glow**: Multi-layer `text-shadow: 0 0 2px currentColor, 0 0 8px currentColor, 0 0 20px rgba(..., 0.3)`
- **Vignette**: `radial-gradient(ellipse at center, transparent 50%, rgba(0,0,0,0.25) 80%, rgba(0,0,0,0.65) 100%)`
- **Screen flicker** (subtle): Opacity animation 0.95-1.0 range, random keyframes, gated behind `prefers-reduced-motion`
- **Chromatic aberration**: Animated `text-shadow` with opposing red/blue offsets at 0.5-1px

### Libraries / References

- [afterglow-crt](https://github.com/HauntedCrusader/afterglow-crt) — Pure CSS CRT overlay with 17 configurable properties and presets including green/amber phosphor
- [cool-retro-term](https://github.com/Swordfish90/cool-retro-term) — Gold standard for CRT simulation (Qt/QML/GLSL shaders). Study its ShaderTerminal.qml for effect parameters
- [CRT CSS by Alec Lownes](https://aleclownes.com/2017/02/01/crt-display.html) — Comprehensive CSS-only CRT techniques
- [Retro CRT Terminal (DEV)](https://dev.to/ekeijl/retro-crt-terminal-screen-in-css-js-4afh) — Practical implementation walkthrough

---

## 3. The CV

What recruiters and search engines see. Server-rendered HTML that works with zero JavaScript.

### Enhanced Terminal Aesthetic

Everything the current site has, plus:

- **Phosphor text glow** on `.prompt` elements and `.hero-ascii` using Catppuccin accent colors
- **Enhanced vignette** overlay for CRT edge darkening
- **Catppuccin-palette ASCII art portrait** replacing the placeholder `<img>` — generated at build time using `ascii-image-converter`, ~50 columns, each character colored with a `<span>` using CSS classes mapped to Catppuccin tokens
- **Progressive rendering** — ASCII art characters reveal one by one when scrolled into view (Intersection Observer)
- **Live neofetch data** — some fields pull real browser info via `web-sys`: `navigator.userAgent`, WebGL renderer string, `performance.memory` (Chrome), making the fastfetch block partially real

### tmux Status Bar Navigation

Replace the current `<nav>` with a tmux-style status bar fixed at the bottom:

```
[houston] 0:home  1:about  2:portfolio*  3:contact-     "zethtren.xyz"  14:23 25-Mar-26
```

- `*` marks the active window (current route)
- `-` marks the last-visited window
- Right side shows hostname and live clock
- Powerline separators using Nerd Font glyphs (or Unicode alternatives)
- Each "window" is a clickable `<a>` — standard navigation underneath the aesthetic
- The [Catppuccin tmux theme](https://github.com/catppuccin/tmux) defines the exact visual conventions to follow

### Dynamic Data from SurrealDB

Replace hardcoded content with server-function queries:

**Language interest tracker with `pv`-style progress bars:**
```
Languages
─────────────────────────────────────────
Python   [████████████████████░░░░] 85%  2,400 hrs  12 projects
Rust     [██████████████████░░░░░░] 75%  1,800 hrs   8 projects
Go       [████████████░░░░░░░░░░░░] 50%    900 hrs   5 projects
SQL      [██████████████████████░░] 90%  3,000 hrs  20 projects
Elixir   [████░░░░░░░░░░░░░░░░░░░░] 15%    120 hrs   1 project
```
Using Unicode block characters: `█` (full), `░` (empty). Data from SurrealDB `skill` table with `proficiency`, `hours`, `project_count` fields.

**htop-style project monitor:**
```
┌─ htop ─ houston@zethtren.xyz ──────────────────────────────────┐
│  PID USER   PR  NI    VIRT    RES STATUS   TIME+  COMMAND      │
│    1 houston  0   0   3.2M   1.1M Running  2y4m  nicular-gcp  │
│    2 houston  0   0   512K   256K Running  0y2m  leptos-cv    │
│    3 houston  0   0   128K    64K Sleeping 4y0m  docker-scrpr │
│    4 houston  0   0    64K    32K Zombie   5y8m  roam-chat    │
│                                                                │
│ Tasks: 4 total, 2 running, 1 sleeping, 1 zombie               │
│ Uptime: 847 days, 14:23:07                                     │
└────────────────────────────────────────────────────────────────┘
```
- **Running** = actively developed, **Sleeping** = stable, **Zombie** = archived
- **TIME+** = age since first commit
- Data from SurrealDB `project` table + GitHub API (cached)

**`git log` career timeline:**
```
* a3f2b1c (HEAD) Lead Developer @ Nicular LLC        (Jul 2022 — Present)
* 8d1e4f7 Data Scientist @ Johnson Group             (Feb 2021 — Apr 2022)
* c7a9b3e QA Analyst @ Yawye                         (May 2020)
* 1e5c9d2 Data Science Immersive @ General Assembly   (Dec 2019 — Mar 2020)
```

**`man houston` — A proper man page:**
```
HOUSTON(1)                   Developer Manual                   HOUSTON(1)

NAME
       houston — lead developer, cloud architect, terminal enthusiast

SYNOPSIS
       houston [--hire] [--collaborate] [--chat]
       houston --skills [CATEGORY]
       houston --projects [--active | --archived]

DESCRIPTION
       Houston is a lead developer and cloud architect specializing in GCP
       infrastructure, Kubernetes orchestration, and build tooling that
       makes teams' lives measurably less painful.

OPTIONS
       --hire
              Open to new opportunities. Initiates the recruitment
              protocol. See also: CONTACT section.

ENVIRONMENT
       STACK    Python, Rust, Go, SQL
       CLOUD    GCP, Cloud Run, GKE, Docker, Kubernetes
       EDITOR   Neovim (the correct choice)
       THEME    Catppuccin Mocha (the correct choice)

BUGS
       Occasionally mass-migrates things into Kubernetes when a simpler
       solution exists. Considers this a feature.

SEE ALSO
       github(1), linkedin(1), email(1)

AUTHOR
       Houston Kelly Bova <Houston@Zethtren.xyz>
```

### TUI Widgets (Unicode / CSS)

All widgets use the ratatui visual language already established in the codebase:

**Unicode block elements for charts:**
- Horizontal fill: `█▉▊▋▌▍▎▏` (8 steps of resolution per character cell)
- Vertical fill: `▁▂▃▄▅▆▇█` (sparklines)
- Shading: `░▒▓█` (progress bars)
- Braille: `U+2800-U+28FF` (256 chars, 2x4 dot matrix per cell — for high-resolution inline charts)
- Box-drawing: `┌┐└┘├┤┬┴┼─│` single, `╔╗╚╝╠╣╦╩╬═║` double, `╭╮╰╯` rounded

**Font note:** JetBrains Mono (already in use) has excellent box-drawing character support. Disable ligatures with `font-variant-ligatures: none` to prevent character merging. Use `ch` CSS unit for all horizontal measurements to maintain grid alignment.

---

## 4. Interactive Terminal

A working command-line emulator. The single most differentiating feature.

### Architecture (Leptos)

- **Hidden `<input>`** always focused, captures keystrokes
- **Visible prompt + text** rendered via reactive signals in styled `<span>` elements
- **Command history** via `Vec<String>` with up/down arrow navigation
- **Tab completion** matching against command names + filesystem entries
- **Virtual filesystem** mapping CV sections to a navigable directory tree

### Virtual Filesystem

```
~/ (home)
├── about.md              # Professional summary
├── contact.md            # Email, GitHub, LinkedIn
├── README.md             # Welcome / help text
├── skills/
│   ├── languages.md      # Python, Rust, Go, SQL
│   ├── infra.md          # GCP, Docker, Kubernetes
│   └── tools.md          # Git, CI/CD, etc.
├── experience/
│   ├── nicular.md        # Lead Developer
│   ├── johnson-group.md  # Data Scientist
│   ├── yawye.md          # QA Analyst
│   └── general-assembly.md
├── projects/
│   ├── docker-scraper.md
│   ├── roam-chat.md
│   ├── nicular-cloud.md
│   ├── crypto-ml.md
│   └── leptos-cv.md
├── education/
│   ├── general-assembly.md
│   └── certifications.md
└── .secret/              # Hidden from `ls`, visible with `ls -a`
    └── hire-me.md
```

**Rust data structure:** `FsNode::Dir(HashMap<String, FsNode>)` / `FsNode::File(String)`. Static tree compiled into the binary.

### Command Set

| Command | Behavior |
|---------|----------|
| `help` | List all available commands with descriptions |
| `ls [path]` | List entries in current or specified directory. Directories in blue, files in green |
| `cat <file>` | Display file content (maps to CV sections) |
| `cd <path>` | Change working directory. Handles `~`, `..`, absolute, relative |
| `pwd` | Print current directory |
| `whoami` | Print identity blurb |
| `neofetch` | Re-render the fastfetch quickstats block |
| `theme <name>` | Switch Catppuccin flavor (reuse existing `apply_theme`/`save_theme`) |
| `clear` | Empty the output buffer |
| `history` | Print command history |
| `man houston` | Full man page (see above) |
| `tree [path]` | Directory tree with `├──`/`└──` characters |
| `grep <pattern> <file>` | Filter lines matching a pattern |
| `echo <text>` | Print text. Support `$USER`, `$SHELL` env vars |
| `uptime` | `up 7 years, 3 months (since General Assembly, Dec 2019)` |
| `top` / `htop` | Projects as processes with status/CPU%/memory |
| `git log` | Career timeline as git commits |
| `kubectl get pods` | Projects rendered as K8s pods |
| `fortune` | Random programming quote from SurrealDB |
| `fortune \| cowsay` | Piped! Quote in ASCII cow |

### Easter Egg Commands

| Command | Response |
|---------|----------|
| `sudo hire-me` | "ACCESS GRANTED" flash + contact info with dramatic effect |
| `rm -rf /` | "Nice try. Permission denied. Also, this is a website." |
| `vim` | Fake vim screen. "To exit vim, close your browser tab." Traps for 3 seconds |
| `exit` | CRT power-off animation — screen collapses to horizontal line → dot → black. Reloads after 2s |
| `sl` | ASCII steam locomotive chugs across the terminal |
| `cmatrix` | Full-screen Matrix rain on canvas overlay (ESC to dismiss) |
| `cowsay <text>` | ASCII cow with speech bubble |
| `lolcat` | Re-renders last output with rainbow colors |
| `sudo su` | "You are now root. Nothing has changed." |
| `:(){ :\|:& };:` | "Fork bomb defused. Nice try." |
| `ping google.com` | "64 bytes from cloud-architect: time=0.42ms — yep, still here" |
| `cat /etc/shadow` | "Access denied. But nice security instincts." |
| `cat /etc/passwd` | "Nice try, pentester." |
| `docker run hello-world` | Your intro text formatted as Docker output |
| `python -c "import this"` | "The Zen of Houston" — personal dev philosophy parodying PEP 20 |
| `ssh` | "Connection refused. But you can reach me at Houston@Zethtren.xyz" |
| `make coffee` | ASCII coffee brewing animation → "Productivity +10%" |
| `screensaver` | Bouncing ASCII "HOUSTON" logo (CSS-only DVD screensaver) |
| `fire` | DOOM fire effect on canvas (Catppuccin colors) |
| `pipes` | pipes.sh screensaver with Catppuccin-colored pipe segments |

### Key References

- [LiveTerm](https://github.com/Cveinnt/LiveTerm) — 4.7k stars. Config-driven terminal portfolio. Study its command dispatch pattern.
- [javascript-terminal](https://github.com/rohanchandra/javascript-terminal) — Immutable state architecture that maps perfectly to Leptos signals.
- [jQuery Terminal](https://terminal.jcubic.pl) — The most sophisticated command parser. Study `parse_command()` and nested interpreter patterns.
- [Bee Kurt's Terminal Portfolio](https://github.com/beekurt/terminal-portfolio) — Virtual filesystem with `cd`/`ls`/`cat`, hidden `.secret/` directory, HN front page.
- [leptos_hotkeys](https://github.com/gaucho-labs/leptos-hotkeys) — Scoped keyboard shortcuts for Leptos. Use scopes as vim modes.

---

## 5. Deep Exploration

### Text Adventure Mode

**This concept appears to be genuinely novel — no one has published a parser-based text adventure CV.**

Activated via `adventure` command or `/adventure` route. The CV becomes a navigable MUD-style world.

```
> look

You are standing in a dimly lit terminal. The phosphor glow of a CRT
monitor illuminates the room. A blinking cursor awaits your command.

Exits: [north] about  [east] portfolio  [south] contact  [west] skills

There is a README.md on the desk.

> go north

## The Archive
You enter a room lined with shelves of technical scrolls. A glowing
orb labeled 'skills' floats nearby. The Timeline stretches to the WEST.

> examine orb
The orb pulses with knowledge: "Python — pipelines, ML, the glue..."
```

**Room graph:** 8-10 rooms mapping to CV sections. NPCs represent past employers. Inventory collects real items (`business card` → copies email, `resume.pdf` → triggers download, `github profile` → opens URL).

**Verbs:** `look`/`l`, `go`/`north`/`n`, `examine`/`x`, `take`/`get`, `talk to`, `inventory`/`i`, `map`/`m`, `help`, `use`

**The `map` command:**
```
    ╔═══════════╗
    ║ ENTRANCE  ║
    ╚═════╤═════╝
          │
    ╔═════╧═════╗
────╢    HALL    ╟────
    ╚═════╤═════╝
     ┌────┼────┐
 ╔═══╧═══╗│╔═══╧═══╗
 ║LIBRARY ║│║WORKSHOP║
 ╚════════╝│╚═══╤═══╝
     ╔═════╧═╗╔═╧════╗
     ║ OFFICE ║║SERVER║
     ╚═══╤═══╝║ ROOM ║
     ╔═══╧═══╗╚══════╝
     ║ARCHIVE ║
     ╚════════╝

 [@] = You are here
```

**Key finding:** Leptos signals are ideal for text adventure state: `RwSignal<Room>`, `RwSignal<HashSet<String>>` for inventory, `RwSignal<Vec<TerminalLine>>` for output. The entire game engine runs in pure Rust/WASM. No external IF engine needed.

**References:**
- [Riskpeep Rust Text Adventure Tutorial](https://www.riskpeep.com/2022/08/make-text-adventure-game-rust-2-1.html) — Most detailed walkthrough of building text adventures in Rust
- [Parchment (iplayif.com)](https://iplayif.com/) — Now uses Rust-compiled-to-WASM interpreters (RemGlk-rs)

### Vim/Neovim Navigation

Progressive enhancement layer. Mouse navigation always works. Vim keybindings are a bonus for power users.

**Basic motions:** `j`/`k` scroll, `gg`/`G` top/bottom, `/` search with `n`/`N` navigation

**Command mode (`:`):**
- `:q` → exit animation
- `:w` → save theme to localStorage
- `:help` → keybinding reference overlay
- `:e about` → navigate to section
- `:colorscheme mocha` → switch theme
- `:Telescope` → open fuzzy finder

**Status bar mode indicator:**
```
-- NORMAL --                              about.md  utf-8  ln 42
```
Color-coded: NORMAL in green, INSERT in blue, COMMAND in yellow, SEARCH in peach.

**Telescope-style fuzzy finder** (Ctrl+P or Space+f):
- Centered floating modal with box-drawing border
- Real-time fuzzy search across all CV content
- `wafu` crate (Rust port of Fuse.js) or `nucleo` (from Helix editor) for matching
- Arrow keys / Ctrl+J/K to navigate, Enter to select, ESC to close

**Which-key popup** (Space leader, 300ms timeout):
```
f  find       t  theme      p  projects
a  about      h  home       ?  help
```

**Alpha-nvim dashboard homepage:**
```
     ██╗  ██╗ ██████╗ ██╗   ██╗███████╗████████╗ ██████╗ ███╗   ██╗
     ...

[a]  about          [p]  portfolio       [t]  change theme
[f]  find           [?]  help            [q]  quit

            Houston Kelly Bova  |  v0.1.0  |  Catppuccin Mocha
```

### Gamification

**RPG Character Sheet** (`cat ~/.character_sheet`):
```
houston — Level 6 Cloud Architect
─────────────────────────────────
STR [████████░░] 8/10  Infrastructure
INT [███████░░░] 7/10  Algorithms/ML
WIS [████████░░] 8/10  System Design
DEX [█████████░] 9/10  Deploy Speed
CON [████████░░] 8/10  Reliability
CHA [███████░░░] 7/10  Documentation

XP: [██████████████░░░░░░] 15,500 / 21,000

Equipment:
  Weapon: Rust +3 (Borrow Checker Mastery)
  Armor:  Kubernetes Helm (AC 18)
  Ring:   GCP Service Account Key
```

**Achievement System:**
```
$ ls ~/achievements/
[x] First Commit        — Started coding journey           (+10 XP)
[x] Polyglot            — Used 5+ programming languages    (+50 XP)
[x] Container Ship      — First Docker deployment          (+10 XP)
[x] Borrow Checker Survivor — Learned Rust                 (+50 XP)
[x] Cloud Walker        — Built first GCP project          (+10 XP)
[x] Full Stack of Clouds — Entire GCP architecture         (+100 XP)
[x] WASM Wizard         — Built this site in Leptos/WASM   (+50 XP)
[x] Lead Dev            — Reviews all prod code            (+100 XP)
[x] 4hr→15min           — Automated reporting pipeline     (+75 XP)
[ ] ???                  — ???                              (+??? XP)
```

**Visitor Achievements** (localStorage):
- "Theme Hopper" — switched theme
- "Catppuccin Connoisseur" — tried all 4 themes
- "Easter Hunter" — found the Konami code
- "Speed Reader" — visited all pages in 30 seconds
- "Source Diver" — opened DevTools
- "Night Owl" — visited between midnight and 5am
- Toast notification: `[!] Achievement Unlocked: Theme Hopper`

**Konami Code** (Up Up Down Down Left Right Left Right B A):
- Triggers full-screen Matrix rain in Catppuccin green
- Or switches to "hacker mode" (green-on-black phosphor theme)

### Skill Graph Visualization

**Recommended: Dual view with toggle `[tree] [graph]`**

**Tree view** (terminal-authentic, default):
```
$ cargo tree --skills

houston v1.0
├── python v5yr
│   ├── ml-tensorflow v4yr
│   │   └── deep-learning v4yr
│   ├── data-pipelines v4yr
│   └── docker v3yr
│       └── kubernetes v2yr
├── rust v2yr
│   ├── wasm v1yr
│   └── leptos v1yr
└── go v2yr
    └── cli-tools v2yr
```

**Graph view** (force-directed SVG):
- `fdg-sim` crate computes layout (Fruchterman-Reingold algorithm)
- Leptos SVG renders `<circle>`, `<line>`, `<text>` reactively
- Nodes colored by category: Languages=`--ctp-green`, Infra=`--ctp-blue`, Tools=`--ctp-mauve`, ML=`--ctp-peach`
- Click a skill → highlights connected projects and experience
- Powered by SurrealDB graph traversal: `SELECT ->uses_skill->project FROM skill:rust`

**Key crates:**
- `petgraph` — Rust graph data structure
- `fdg-sim` — Force-directed layout using petgraph
- `ascii-petgraph` — Renders petgraph as ASCII art with box-drawing characters
- `catppuccin` — Programmatic access to palette values

---

## 6. Visual Effects

All opt-in. All gated behind `prefers-reduced-motion`. All triggered by commands or idle timeout.

### Matrix Rain (`cmatrix` command)
- Canvas-based. 96 columns at 1920px / 20px font.
- Semi-transparent `--ctp-crust` fill for trail fade: `rgba(17, 17, 27, 0.05)`
- Head character in `--ctp-green` at full brightness
- Mix of katakana (U+FF66-FF9D), Latin, digits, symbols
- 30fps via `requestAnimationFrame` with timestamp throttle
- [cmatrix by jcubic](https://github.com/jcubic/cmatrix) — reference implementation

### DOOM Fire (`fire` command)
- 1D heat buffer, propagate upward with random decay
- Color palette: `--ctp-crust` → `--ctp-surface0` → `--ctp-red` → `--ctp-peach` → `--ctp-yellow` → `--ctp-text`
- Canvas `putImageData` for pixel-level rendering, or ASCII `░▒▓█` variant
- [Fabien Sanglard's DOOM fire article](https://fabiensanglard.net/doom_fire_psx/) — algorithm reference
- [Rust DOOM fire FX](https://notryanb.github.io/rust-doom-fire-fx.html) — WASM reference

### Pipes Screensaver (`pipes` command or idle timeout)
- 2D character grid, pipes grow in random directions
- Box-drawing turns: `┏┓┗┛━┃` for direction changes
- Each new pipe gets a different Catppuccin accent color
- DOM rendering (`<pre>` textContent update) at ~10fps

### Bouncing Logo (`screensaver` command or idle timeout)
- **Pure CSS, zero JS.** Two nested `<div>`s with different animation durations
- Outer div: horizontal bounce (7.3s), inner div: vertical bounce (5.1s)
- Color cycles through Catppuccin accents via `steps()` timing
- Content: the "HOUSTON" ASCII art block

### Glitch Effects (theme switch transition)
- 200ms of chromatic aberration + screen tear
- CSS `clip-path` rapidly slicing horizontal bands
- `text-shadow` with opposing red/blue offsets
- 50ms flash to `--ctp-surface0`
- Apply new theme
- 100ms reverse glitch as new theme "stabilizes"

### ASCII Fluid Simulation
- SPH (Smoothed Particle Hydrodynamics) with ~200 particles
- Rendered as block characters `░▒▓█`
- [HarikrishnanBalagopal/ascii-fluid-simulation](https://github.com/HarikrishnanBalagopal/ascii-fluid-simulation) — Rust/WASM reference

---

## 7. Sound Design

All OFF by default. All synthesized via Web Audio API (zero file downloads for most sounds). All independently volume-controllable. All respect `prefers-reduced-motion`.

### Sound Channels

| Channel | Sounds | Default |
|---------|--------|---------|
| Keyboard | Mechanical key clicks (Blue/Brown/Red profiles) | Off |
| Ambient | CRT 60Hz hum + 15.7kHz flyback whine | Off |
| Effects | BIOS beep, degauss, terminal bell, CRT power-off | Off |
| Notifications | Achievement unlock, error beep | Off |

### Synthesis Recipes (Web Audio API, zero downloads)

- **CRT Hum:** 60Hz sine wave (gain 0.01) + 120Hz harmonic (gain 0.005) + 15734Hz sine (gain 0.003)
- **BIOS Beep:** 1000Hz square wave, 200ms duration, sharp envelope
- **Terminal Bell:** 800Hz sine wave, 100ms, gentle release
- **CRT Power-Off:** Frequency sweep 2000Hz → 200Hz over 200ms + noise burst

### Sampled Sounds (~40-50KB total, Opus compressed)

- **Keyboard clicks:** 3 switch types x 5 variations = 15 samples (~30KB). Random selection + slight pitch/volume variance prevents repetition
- **Degauss:** 1 sample (~10KB). Played on theme switch or first load
- **HDD Seek:** 1 sample (~5KB). During boot sequence

### References

- Web Audio API is fully accessible via `web-sys` — `AudioContext`, `OscillatorNode`, `GainNode`, `BiquadFilterNode`
- The audio module should be a standalone Rust module communicating via Leptos signals
- `AudioContext` must be created/resumed on user gesture (click/keypress)

---

## 8. SurrealDB Data Model

### The Unified Graph

Everything connects to everything. One database serves both the public CV and the private life dashboard.

#### CV Tables (public read, admin write)

```sql
DEFINE TABLE skill SCHEMAFULL;
DEFINE FIELD name ON skill TYPE string;
DEFINE FIELD category ON skill TYPE string;  -- "language", "infra", "tool", "ml"
DEFINE FIELD proficiency ON skill TYPE int;  -- 1-100
DEFINE FIELD hours ON skill TYPE float;
DEFINE FIELD years ON skill TYPE float;
DEFINE FIELD last_used ON skill TYPE datetime;
DEFINE FIELD icon ON skill TYPE option<string>;

DEFINE TABLE project SCHEMAFULL;
DEFINE FIELD title ON project TYPE string;
DEFINE FIELD description ON project TYPE string;
DEFINE FIELD tags ON project TYPE array<string>;
DEFINE FIELD source_url ON project TYPE option<string>;
DEFINE FIELD status ON project TYPE string;  -- "active", "sleeping", "zombie"
DEFINE FIELD created ON project TYPE datetime;
DEFINE FIELD sort_order ON project TYPE int;
DEFINE FIELD visible ON project TYPE bool DEFAULT true;

DEFINE TABLE experience SCHEMAFULL;
DEFINE FIELD title ON experience TYPE string;
DEFINE FIELD company ON experience TYPE string;
DEFINE FIELD start_date ON experience TYPE datetime;
DEFINE FIELD end_date ON experience TYPE option<datetime>;
DEFINE FIELD description ON experience TYPE string;

DEFINE TABLE certification SCHEMAFULL;
DEFINE FIELD title ON certification TYPE string;
DEFINE FIELD issuer ON certification TYPE string;
DEFINE FIELD date ON certification TYPE string;

DEFINE TABLE fortune SCHEMAFULL;
DEFINE FIELD text ON fortune TYPE string;
DEFINE FIELD author ON fortune TYPE option<string>;

DEFINE TABLE page_view SCHEMAFULL;
DEFINE FIELD path ON page_view TYPE string;
DEFINE FIELD timestamp ON page_view TYPE datetime DEFAULT time::now();
DEFINE FIELD referrer ON page_view TYPE option<string>;
```

#### Graph Relations (RELATE)

```sql
-- Skills enable other skills (dependency tree)
RELATE skill:python -> ENABLES -> skill:ml;
RELATE skill:ml -> ENABLES -> skill:deep_learning;
RELATE skill:docker -> ENABLES -> skill:kubernetes;
RELATE skill:rust -> ENABLES -> skill:wasm;
RELATE skill:wasm -> ENABLES -> skill:leptos;

-- Projects use skills (with edge metadata)
RELATE project:docker_scraper -> USES_SKILL -> skill:python SET role = "primary";
RELATE project:leptos_cv -> USES_SKILL -> skill:rust SET role = "primary";
RELATE project:leptos_cv -> USES_SKILL -> skill:wasm SET role = "primary";

-- Experience produced projects
RELATE experience:nicular -> PRODUCED -> project:nicular_cloud;
RELATE experience:johnson -> PRODUCED -> project:marketing_intel;

-- Experience required skills
RELATE experience:nicular -> REQUIRED -> skill:gcp;
RELATE experience:nicular -> REQUIRED -> skill:kubernetes;

-- Certifications validate skills
RELATE certification:deep_learning -> VALIDATES -> skill:ml;
```

#### Powerful Graph Queries

```sql
-- "What skills does this project use?"
SELECT ->USES_SKILL->skill.name FROM project:leptos_cv;

-- "What projects use Rust?"
SELECT <-USES_SKILL<-project.title FROM skill:rust;

-- "Skills with their project count, sorted"
SELECT name, count(<-USES_SKILL<-project) AS project_count
  FROM skill ORDER BY project_count DESC;

-- "Career path: skills gained at each job"
SELECT company, <-REQUIRED<-skill.name AS skills
  FROM experience ORDER BY start_date;

-- "Skill XP calculation"
SELECT name,
    (years * 100) +
    (count(<-USES_SKILL<-project) * 50) +
    (count(<-VALIDATES<-certification) * 200) AS xp
  FROM skill;
```

#### Permissions (Public vs Private)

```sql
-- Public (CV visitors): read-only on specific tables
DEFINE TABLE skill PERMISSIONS
  FOR select FULL
  FOR create, update, delete WHERE $auth.role = 'admin';

DEFINE TABLE project PERMISSIONS
  FOR select WHERE visible = true
  FOR create, update, delete WHERE $auth.role = 'admin';

-- Private (dashboard): admin-only everything
DEFINE TABLE task PERMISSIONS
  FOR select, create, update, delete WHERE $auth.role = 'admin';
```

---

## 9. The Dashboard — Personal Life OS

Not just a CV admin panel. A full **personal operating system** powered by Phoenix LiveView, SurrealDB's unified graph, and local AI.

### The Interface: A Terminal Multiplexer

The dashboard IS a tmux session. Every module is a "pane." The Catppuccin terminal aesthetic from the CV carries over entirely — same CSS variables, same JetBrains Mono, same TUI widgets.

```
┌─ htop ──────────────────────┬─ tasks ─────────────────────────┐
│ Service     CPU  MEM Status │ [ ] Deploy CV v0.5.0     [!]   │
│ leptos-cv   2%   32M  ✓    │ [x] Fix Latte contrast   [done]│
│ surrealdb   5%  256M  ✓    │ [ ] Write blog post      [wip] │
│ phoenix     3%  128M  ✓    │ [ ] Update resume        [todo]│
│ ollama     45% 8.2G   ✓    │                                 │
├─ analytics ─────────────────┼─ ai ────────────────────────────┤
│ Visitors today: 47          │ houston> What did I work on     │
│ Top page: /portfolio (62%)  │          this week?             │
│ Referrer: linkedin.com (31%)│                                 │
│ ▁▂▃▅▇█▇▅▃▂▁▃▅▇ (7d trend)  │ Based on your git commits and  │
│                             │ completed tasks, you:           │
├─ journal ───────────────────┤ - Shipped CV v0.4.0             │
│ [2026-03-25] Productive day │ - Fixed 3 accessibility bugs    │
│ Mood: ████████░░ 8/10       │ - Started Phoenix dashboard     │
│ Energy: ██████░░░░ 6/10     │ - Read 2 chapters of DDIA      │
│ Sleep: 7.2 hrs (▲ 0.5)     │                                 │
└─────────────────────────────┴─────────────────────────────────┘
[houston] htop  tasks  analytics*  journal  finance  ai     14:23
```

### Dashboard Modules

#### Core (Phase 1)

**CV Content Manager**
- Edit experience, projects, skills, certifications in SurrealDB
- Content versioning (diff view styled as `git diff`)
- Markdown editor with Catppuccin syntax highlighting
- Live preview showing how changes look on the CV

**Analytics**
- Page views, unique visitors, referrers, user agents
- Time-series charts using Contex (pure Elixir SVG charting)
- Real-time visitor feed (LiveView + PubSub)
- Geographic distribution (hashed IPs for privacy)
- Session flow: `/ → /about → /portfolio → [exit]`

**Task / Goal Management**
- Kanban board or GTD-style lists
- Priority, deadline, tags, projects
- Recurring tasks
- Habits tracker with streaks
- OKR tracking with progress bars

#### Life Management (Phase 2)

**Finance**
- Expense tracking with AI auto-categorization
- Budget vs actual with `pv`-style progress bars
- Net worth over time sparkline
- Subscription tracker ("what do I pay for monthly?")
- Investment portfolio overview

**Health & Wellness**
- Sleep tracking data visualization
- Workout logging with progress charts
- Mood/energy check-ins (daily, stored as time-series in SurrealDB)
- Correlation analysis: sleep vs productivity, exercise vs mood

**Knowledge Management**
- Bookmarks with tagging and full-text search
- Reading list with progress bars (currently reading / completed / want to read)
- Code snippet library with syntax highlighting
- Learning tracker (courses, tutorials, certifications)
- Personal wiki / Zettelkasten with bidirectional linking — powered by SurrealDB graph relations

**Contact CRM**
- Track relationships: name, company, how you met, last contacted
- Notes per contact
- Relationship graph visualization (SurrealDB graph)

**Journal**
- Daily entries with mood, energy, gratitude
- AI-generated prompts based on recent activity
- Pattern recognition: "You tend to be most productive on Tuesdays after exercise"
- Searchable archive with full-text search

#### DevOps / Career (Phase 3)

**GitHub Dashboard**
- Contribution analytics beyond the green grid
- Per-repo commit frequency, PR merge times, issue close rates
- Language breakdown over time
- Open source project health monitoring

**Blog / Content Publishing**
- Draft posts in Markdown with live preview
- Scheduled publishing via Oban background jobs
- SEO preview (how it looks in Google/LinkedIn/Twitter)
- Auto-generate social media snippets with AI

**Job Market Intelligence**
- Track interesting job postings
- Salary benchmarking data
- Skill gap analysis: "Jobs requiring X that you don't have yet"
- Application tracker if actively searching

### Tech Stack for Dashboard

- **Phoenix LiveView** — real-time UI, zero JS for most features
- **Req** — HTTP client for SurrealDB REST API (no mature Elixir SurrealDB driver exists)
- **phx.gen.auth** — session-based authentication, single admin user, no registration
- **nimble_totp** — TOTP 2FA
- **Oban** — background job processing (scheduled content, data sync, AI tasks)
- **Contex** — pure Elixir SVG charting with Catppuccin colors
- **Phoenix.PubSub** — real-time dashboard updates
- **Nx/Bumblebee/EXLA** — ML from Elixir (see AI section)
- **IAP (Identity-Aware Proxy)** at GKE ingress level — zero-trust auth before traffic even reaches Phoenix

---

## 10. Local AI / ML Integration

Hardware: **RTX 3060 (12GB VRAM)** + **128GB RAM**. This is a serious local AI rig.

### What Fits on a 3060

| Model | Size | VRAM | Use Case |
|-------|------|------|----------|
| Llama 3.1 8B (Q4) | ~4.5GB | ~5GB | General assistant, writing, summarization |
| Mistral 7B (Q4) | ~4GB | ~5GB | Fast general-purpose |
| Phi-3 Mini (3.8B) | ~2.5GB | ~3GB | Lightweight, fast tasks |
| CodeLlama 7B (Q4) | ~4GB | ~5GB | Code review, generation |
| Nomic Embed Text | ~0.3GB | ~1GB | Embeddings for RAG |
| Whisper Small/Medium | ~0.5-1.5GB | ~2-3GB | Speech-to-text |
| Stable Diffusion 1.5 | ~4GB | ~6GB | Image generation |

**Key insight:** With 128GB RAM, you can run **multiple models simultaneously** using CPU inference as overflow. Keep the primary LLM on GPU, embeddings on GPU, and secondary models on CPU. Ollama manages this automatically.

### AI on the CV (Public-Facing)

**`ask houston` terminal command:**
```
$ ask houston about kubernetes

Houston says: I've been running production Kubernetes clusters at
Nicular since 2022. I migrated the entire legacy GCP-managed app
fleet into GKE, built the deploy tooling so the team ships to K8s
without touching infrastructure, and review every line that goes to
production. My approach is: boring infrastructure is good
infrastructure.

[Source: experience/nicular.md, skills/infra.md]
```

Implementation: RAG (Retrieval-Augmented Generation) over all CV content.
1. Embed all CV text (skills, experience, projects, about) using `nomic-embed-text` via Ollama
2. Store embeddings in SurrealDB (vector search) or a sidecar Qdrant
3. On query: embed the question → vector similarity search → retrieve top-K relevant sections → feed to Llama 3.1 as context → stream response
4. Server function in Leptos calls Ollama API → streams response back as terminal output

**Automated skill assessment from GitHub:**
- CronJob fetches repo data (languages, commits, activity) via GitHub API
- AI analyzes: "Based on 2,400 commits across 12 Python repos over 5 years, proficiency estimate: 85%"
- Updates SurrealDB `skill.proficiency` field
- CV progress bars update automatically

**Smart project descriptions:**
- AI generates/refines project descriptions from GitHub READMEs
- Stored in SurrealDB, editable in dashboard

### AI on the Dashboard (Private)

**Personal AI Assistant (the big dream):**
- RAG over ALL dashboard data: tasks, journal, bookmarks, expenses, health, contacts, notes
- Natural language queries: "How much did I spend on food last month?" "What was that article about distributed systems I saved in January?" "What tasks are blocking my Q2 goals?"
- Available as a chat pane in the dashboard AND as a terminal command
- Learns your writing style from journal entries, blog posts, commit messages
- Gets smarter the longer you use the system — all private, all local

**Smart task prioritization:**
- Analyzes deadlines, historical completion patterns, energy levels (from mood data)
- "Based on your patterns, you're most productive on Tuesday mornings. Schedule the architecture review then."

**Automatic expense categorization:**
- Upload bank CSV → AI categorizes each transaction
- Learns from corrections: "No, that $45 at Home Depot was 'home improvement', not 'shopping'"

**Meeting note summarization:**
- Whisper transcribes audio → LLM extracts action items
- Action items auto-created as tasks in the dashboard

**Spaced repetition optimization:**
- Tracks what you've learned and when
- AI determines optimal review intervals
- "You haven't reviewed Kubernetes networking concepts in 3 weeks. Quiz?"

**Anomaly detection:**
- Monitors health, spending, productivity time-series
- "Your sleep has decreased by 1.2 hours/night over the last 2 weeks. Correlated with increased caffeine spending."

### AI Infrastructure

**Ollama** (recommended for serving):
- Docker container with NVIDIA GPU passthrough
- REST API at `http://ollama:11434`
- Pull models: `ollama pull llama3.1:8b`, `ollama pull nomic-embed-text`
- Streaming responses via Server-Sent Events
- Phoenix LiveView connects via WebSocket → streams AI responses token-by-token into the chat pane

**Elixir/Nx/Bumblebee:**
- Nx is Elixir's numerical computing library (like NumPy)
- Bumblebee provides pre-trained model support (Llama, Whisper, CLIP, Stable Diffusion)
- EXLA backend enables GPU acceleration via XLA (supports CUDA)
- Can run embedding models directly in the Phoenix process — no separate service needed
- Livebook (Elixir's Jupyter equivalent) can be embedded for ad-hoc data analysis

**Vector Storage:**
- SurrealDB is exploring vector search capabilities (check latest docs)
- Alternative: Qdrant sidecar container (purpose-built vector DB, ~50MB image)
- Or: pgvector if you add PostgreSQL
- Embeddings stored alongside the graph data they describe

**Fine-Tuning (QLoRA on 3060):**
- QLoRA enables fine-tuning 7B models on 12GB VRAM
- Fine-tune on your writing (journal entries, blog posts, commit messages) to capture your voice
- Fine-tune on your CV data for more accurate `ask houston` responses
- Use `axolotl` or `unsloth` for easy QLoRA training

### The Evolution Model

The AI doesn't just answer questions — it **evolves** with you:

1. **Month 1:** Basic RAG over CV data. `ask houston` works but answers are generic.
2. **Month 3:** Fine-tuned on your writing style. Answers sound like you. Dashboard AI categorizes expenses accurately.
3. **Month 6:** Pattern recognition kicks in. "You're learning Elixir at 2x the rate you learned Go. At this pace, you'll hit 'proficient' by September."
4. **Month 12:** The AI is a genuine personal assistant. It knows your schedule, your goals, your health patterns, your knowledge graph. It can draft emails in your voice, suggest what to work on, and notice when something is off.

All private. All local. No data leaves your infrastructure.

---

## 11. GKE Deployment

### Cluster: GKE Standard, Zonal, Single Spot VM

| Component | Cost/Month |
|-----------|-----------|
| GKE management fee (zonal, free tier) | $0 |
| 1x e2-small spot VM (2 vCPU, 2GB) | ~$5 |
| 10Gi pd-standard PVC (SurrealDB) | ~$0.40 |
| 1x L7 LB forwarding rule | ~$18 |
| Static IP | $0 (while attached) |
| Egress (low traffic) | ~$1 |
| **Total** | **~$25/month** |

**For AI workloads:** Add a GPU node (T4 spot: ~$110/mo, or run AI on a separate home server and expose via Tailscale/WireGuard).

### Kustomize Layout

```
k8s/
├── base/
│   ├── kustomization.yaml
│   ├── namespace.yaml
│   ├── leptos-cv/
│   │   ├── deployment.yaml      # Leptos SSR (Axum) pod
│   │   ├── service.yaml         # ClusterIP
│   │   └── kustomization.yaml
│   ├── phoenix-admin/
│   │   ├── deployment.yaml      # Phoenix LiveView pod
│   │   ├── service.yaml         # ClusterIP
│   │   └── kustomization.yaml
│   ├── surrealdb/
│   │   ├── statefulset.yaml     # SurrealDB with PVC
│   │   ├── service.yaml         # ClusterIP (internal only)
│   │   ├── pvc.yaml
│   │   ├── networkpolicy.yaml   # Only Phoenix + Leptos can reach it
│   │   └── kustomization.yaml
│   └── ingress/
│       ├── ingress.yaml         # L7 LB routing
│       ├── managed-cert.yaml    # Google Managed Certificates
│       └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml
    │   └── resource-limits-patch.yaml
    └── prod/
        ├── kustomization.yaml
        └── resource-limits-patch.yaml
```

### Ingress Routing

```yaml
spec:
  rules:
  - host: zethtren.xyz
    http:
      paths:
      - path: /
        backend:
          service: leptos-cv-svc
          port: 8080
  - host: admin.zethtren.xyz
    http:
      paths:
      - path: /
        backend:
          service: phoenix-admin-svc
          port: 4000
```

### Security

- **SurrealDB:** ClusterIP only + NetworkPolicy allowing only `app: leptos-cv` and `app: phoenix-admin` pods
- **Phoenix Dashboard:** IAP (Identity-Aware Proxy) at ingress — Google handles auth before traffic reaches the pod. Whitelist your Google account. Zero extra pods.
- **TLS:** Google Managed Certificates — automatic issuance and renewal
- **Secrets:** Kubernetes Secrets for `SURREAL_USER`, `SURREAL_PASS`, `SECRET_KEY_BASE`, `SURREALDB_URL`

### CI/CD (GitHub Actions)

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'apps/leptos-cv/**'  # Only rebuild what changed
      - 'apps/phoenix-dashboard/**'
      - 'k8s/**'

jobs:
  build-leptos:
    if: contains(github.event.head_commit.modified, 'apps/leptos-cv/')
    steps:
      - docker build → Artifact Registry
      - kustomize edit set image → kubectl apply

  build-phoenix:
    if: contains(github.event.head_commit.modified, 'apps/phoenix-dashboard/')
    steps:
      - docker build → Artifact Registry
      - kustomize edit set image → kubectl apply
```

Workload Identity Federation for GKE auth — no service account keys stored in GitHub.

### Docker Images

**Leptos SSR:**
```dockerfile
# Builder: rust + cargo-leptos + wasm target
FROM rust:1.78 AS builder
# ... build with cargo-leptos

# Runtime: just the binary + site/ assets
FROM debian:bookworm-slim
COPY --from=builder /app/target/release/leptos-cv .
COPY --from=builder /app/target/site ./site
EXPOSE 8080
CMD ["./leptos-cv"]
```
Image size: ~15-20MB. Pod resources: 64MB RAM, 100m CPU.

**Phoenix:**
```dockerfile
FROM elixir:1.16-alpine AS build
# ... mix release

FROM alpine:3.19
COPY --from=build /app/_build/prod/rel/cv_admin .
EXPOSE 4000
CMD ["bin/cv_admin", "start"]
```
Image size: ~30-50MB. Pod resources: 256MB RAM, 250m CPU.

---

## 12. PWA

### "Install houston"

The CV is installable as a standalone app. No browser chrome — looks like a real terminal application.

**Custom install prompt (intercept `beforeinstallprompt`):**
```
$ sudo apt install houston
Reading package lists... Done
Building dependency tree... Done
The following NEW packages will be installed:
  houston (0.4.0-1) [2.1 MB]
Do you want to continue? [Y/n]
```
"Y" triggers `deferredPrompt.prompt()`.

**manifest.json:**
```json
{
  "name": "houston — Houston Kelly Bova",
  "short_name": "~/",
  "display": "standalone",
  "background_color": "#1e1e2e",
  "theme_color": "#cba6f7",
  "shortcuts": [
    { "name": "$ cat about.md", "url": "/about" },
    { "name": "$ ls projects/", "url": "/portfolio" }
  ]
}
```

**Offline:** Service worker precaches WASM + HTML + CSS + fonts + static data snapshot. Works on a plane.

**Icon:** A `>_` terminal prompt in Catppuccin mauve on Catppuccin base background.

**Note:** `beforeinstallprompt` is Chromium-only. Safari users get manual "Add to Home Screen" instructions themed as `man houston-install`.

---

## 13. Accessibility

### Critical Fixes Needed (Current Code)

1. **Add `prefers-reduced-motion` media query** — currently absent entirely. Must disable cursor blink, all transitions, scroll-behavior smooth.

2. **Add `role="img"` + `aria-label` to ASCII art blocks** — the hero "HOUSTON" and fetch logo are completely unintelligible to screen readers (reads every box-drawing character).

3. **Add `aria-label` to theme buttons** — currently empty `<button>` elements with only `title` attribute (unreliable for AT).

4. **Add skip-to-content link** — WCAG 2.4.1.

5. **Fix Latte contrast failures:**
   - Green `#40a02b` on base `#eff1f5` = **2.95:1** (FAIL, needs 4.5:1)
   - Blue `#1e66f5` on base = **4.34:1** (FAIL)
   - Subtext0 `#6c6f85` on base = **4.36:1** (FAIL)

6. **Fix Mocha overlay1 on base** (timeline dates) — 4.43:1, borderline FAIL. Use `overlay2` or `subtext0`.

7. **Add visible focus indicators** — custom outlines for dark themes where browser defaults are invisible.

8. **Add `@media print` stylesheet** — currently prints dark-on-dark.

9. **Add OpenGraph meta tags** to `index.html` for social media previews.

10. **Add `aria-hidden="true"` to decorative elements** — terminal dots, color swatches, `::before` pseudo-content.

### Guidelines for New Features

- All CRT effects, animations, and sound: progressive enhancement, off by default
- Interactive terminal: `role="log"` with `aria-live="polite"` on output, proper `<input>` for command line
- Vim keybindings: only capture when no `<input>` is focused, never override `Ctrl+F/L/N/T/W`, provide disable toggle
- Text adventure: all content also available in static HTML view
- ASCII art: always include `role="img"` + `aria-label`
- Add `prefers-contrast: more` support
- Add `forced-colors` (Windows High Contrast) support
- All features must degrade gracefully to readable content

### Catppuccin Cursor Fix

The current cursor uses `--ctp-text`. The official Catppuccin style guide specifies **Rosewater** for cursors. Small but signals adherence to the spec.

---

## 14. Catppuccin Ecosystem

### Current Status

The project correctly implements all four Catppuccin flavors with accurate hex values and the `--ctp-` prefix convention. The color usage largely follows the official style guide.

### Integration Opportunities

- **`@catppuccin/highlightjs`** — Official Highlight.js themes. "Variable version" reuses existing `--ctp-` CSS variables. Use for syntax-highlighted file viewing (`cat main.rs` command).
- **WebTUI** (`webtui.ironclad.sh`) — CSS library for terminal UIs in browsers with an official `@webtui/theme-catppuccin` plugin. Consider as a CSS foundation replacement.
- **Nerd Fonts** — Available as web fonts via [nerdfont-webfonts](https://mshaugh.github.io/nerdfont-webfonts/). JetBrains Mono Nerd Font variant adds Powerline separators and devicons for the tmux status bar.

### CRT Phosphor Themes (Beyond Catppuccin)

| Theme | Color | Hex | Origin | Contrast on Black |
|-------|-------|-----|--------|-------------------|
| P1 Green | Phosphor green | `#33ff33` | VT100, Apple II | ~15:1 |
| P3 Amber | Phosphor amber | `#ffb000` | IBM 5151 | ~12:1 |
| P4 White | Phosphor white | `#e8e6e3` | Early Macintosh | ~19:1 |
| P11 Blue | Phosphor blue | `#00aaff` | Oscilloscopes | ~8:1 |

All paired with near-black background (`#0a0a0a`) and appropriate `text-shadow` glow. Offered alongside Catppuccin flavors in the GRUB menu.

### Rice Inspector Easter Egg

`rice` or `dotfiles` command:
```
houston@dotfiles
─────────────────
OS      ~ Arch Linux (btw)
WM      ~ Hyprland
Shell   ~ zsh + starship
Term    ~ kitty
Editor  ~ neovim (LazyVim)
Font    ~ JetBrains Mono Nerd Font
Theme   ~ Catppuccin Mocha
Bar     ~ waybar
Launch  ~ rofi
Files   ~ yazi
```

### Catppuccin ANSI Color Mapping (Official)

| ANSI | Color Name | Dark Flavors | Latte |
|------|------------|-------------|-------|
| 0 | Black | Surface 1 | Subtext 1 |
| 1 | Red | Red | Red |
| 2 | Green | Green | Green |
| 3 | Yellow | Yellow | Yellow |
| 4 | Blue | Blue | Blue |
| 5 | Magenta | Pink | Pink |
| 6 | Cyan | Teal | Teal |
| 7 | White | Subtext 0 | Surface 2 |

---

## 15. Priority Roadmap

### Phase 0: Foundation
- [ ] Switch to Leptos SSR + Islands (`cargo-leptos`, Axum)
- [ ] SurrealDB schemas + seed data (migrate hardcoded content)
- [ ] Accessibility fixes (ARIA, contrast, reduced-motion, skip-link)
- [ ] Basic Kustomize manifests + Dockerfiles

### Phase 1: The Terminal Experience
- [ ] Interactive terminal emulator (command parser, history, tab completion)
- [ ] Virtual filesystem mapping CV sections
- [ ] Core commands: `help`, `ls`, `cat`, `cd`, `whoami`, `man houston`
- [ ] Easter egg commands: `sudo hire-me`, `vim`, `exit`, `cowsay`
- [ ] CRT boot sequence with GRUB theme picker
- [ ] tmux status bar navigation
- [ ] Dynamic language progress bars from SurrealDB

### Phase 2: Deep Features
- [ ] Text adventure mode
- [ ] htop-style project monitor
- [ ] Skill graph visualization (tree + force-directed)
- [ ] RPG character sheet + achievement system
- [ ] Visitor achievements (localStorage)
- [ ] PWA manifest + service worker
- [ ] CRT phosphor themes (green, amber)
- [ ] ASCII art portrait
- [ ] Catppuccin syntax highlighting for `cat *.rs`

### Phase 3: Visual Polish
- [ ] Matrix rain, DOOM fire, pipes screensaver
- [ ] Glitch transition effects
- [ ] Sound design (Web Audio API synthesis)
- [ ] Vim/neovim keybindings
- [ ] Telescope fuzzy finder
- [ ] Print stylesheet

### Phase 4: The Dashboard
- [ ] Phoenix LiveView project scaffold
- [ ] Auth (phx.gen.auth + TOTP)
- [ ] CV content manager (CRUD for SurrealDB data)
- [ ] Analytics dashboard (page views, referrers)
- [ ] Task/goal management
- [ ] GKE deployment (Ingress, IAP, managed certs)

### Phase 5: Life OS
- [ ] Journal with mood/energy tracking
- [ ] Finance tracker
- [ ] Knowledge management (bookmarks, reading list, wiki)
- [ ] Contact CRM
- [ ] Health/wellness tracking
- [ ] GitHub analytics dashboard

### Phase 6: AI Integration
- [ ] Ollama deployment (GPU pod or home server)
- [ ] `ask houston` RAG command on CV
- [ ] Dashboard AI chat pane
- [ ] Automatic expense categorization
- [ ] Smart task prioritization
- [ ] Whisper voice input
- [ ] Fine-tuning on personal data (QLoRA)
- [ ] Natural language data queries

---

## References & Key Resources

### Terminal Portfolios
- [LiveTerm](https://github.com/Cveinnt/LiveTerm) — 4.7k stars, config-driven terminal portfolio
- [satnaing/terminal-portfolio](https://github.com/satnaing/terminal-portfolio) — Astro terminal portfolio with themes
- [javascript-terminal](https://github.com/rohanchandra/javascript-terminal) — Immutable state terminal library
- [jQuery Terminal](https://terminal.jcubic.pl) — Feature-rich terminal emulator library
- [Bee Kurt's Terminal Portfolio](https://github.com/beekurt/terminal-portfolio) — Virtual filesystem, HN front page

### CRT Effects
- [afterglow-crt](https://github.com/HauntedCrusader/afterglow-crt) — Pure CSS CRT overlay
- [cool-retro-term](https://github.com/Swordfish90/cool-retro-term) — Gold standard CRT simulation
- [CRT CSS (Alec Lownes)](https://aleclownes.com/2017/02/01/crt-display.html)

### Leptos
- [Leptos Book](https://book.leptos.dev/) — Official documentation
- [Leptos Islands](https://book.leptos.dev/islands.html) — Islands architecture guide
- [Leptos SSR Deployment](https://book.leptos.dev/deployment/ssr.html)
- [leptos_hotkeys](https://github.com/gaucho-labs/leptos-hotkeys) — Keyboard shortcuts

### SurrealDB
- [SurrealDB Docs](https://surrealdb.com/docs/)
- [SurrealDB Graph Model](https://surrealdb.com/docs/surrealdb/models/graph)
- [SurrealDB Helm Chart](https://helm.surrealdb.com)

### Catppuccin
- [Catppuccin Style Guide](https://github.com/catppuccin/catppuccin/blob/main/docs/style-guide.md)
- [Catppuccin Palette](https://catppuccin.com/palette/)
- [Catppuccin Highlight.js](https://github.com/catppuccin/highlightjs)
- [WebTUI + Catppuccin](https://webtui.ironclad.sh/plugins/theme-catppuccin/)
- [Nerd Font Web Fonts](https://mshaugh.github.io/nerdfont-webfonts/)

### AI/ML
- [Ollama](https://ollama.ai/) — Local LLM serving
- [Elixir Nx](https://github.com/elixir-nx/nx) — Numerical computing for Elixir
- [Bumblebee](https://github.com/elixir-nx/bumblebee) — Pre-trained models for Elixir
- [QLoRA Paper](https://arxiv.org/abs/2305.14314)

### Rust Crates
- `petgraph` — Graph data structure
- `fdg-sim` — Force-directed graph layout
- `ascii-petgraph` — ASCII graph rendering
- `catppuccin` — Palette values in Rust
- `wafu` — Fuzzy search (Rust port of Fuse.js)
- `nucleo` — Fuzzy matcher from Helix editor

### Visual Effects
- [DOOM Fire (Fabien Sanglard)](https://fabiensanglard.net/doom_fire_psx/)
- [Rust DOOM Fire WASM](https://notryanb.github.io/rust-doom-fire-fx.html)
- [cmatrix.js](https://github.com/jcubic/cmatrix)
- [ASCII Fluid Sim (Rust/WASM)](https://github.com/HarikrishnanBalagopal/ascii-fluid-simulation)
- [WarpSpeed.js (Starfield)](https://github.com/adolfintel/warpspeed)

### Text Adventure
- [Riskpeep Rust Text Adventure Tutorial](https://www.riskpeep.com/2022/08/make-text-adventure-game-rust-2-1.html)
- [Parchment (iplayif.com)](https://iplayif.com/) — IF interpreter, now Rust/WASM
- [Awesome Interactive Fiction](https://github.com/tajmone/awesome-interactive-fiction)

---

# EXPANDED: The Dream Dashboard, AI, and Unified Data Layer

*Research from 4 additional deep-dive agents on local AI, personal life OS, SurrealDB graph analytics, and Phoenix LiveView dashboard architecture.*

---

## Appendix A: The Dashboard — Personal Life OS (Expanded)

### The Gap in the Market

No single self-hosted tool unifies all life domains well. The closest attempts:
- **Personal Management System** (Volmarg) — PHP/Symfony, covers todos/notes/payments/contacts but limited APIs and dated UI
- **Notion Life OS templates** — conceptually comprehensive but locked into proprietary platform
- The opportunity: a performant, self-hosted, unified personal life dashboard in a terminal aesthetic

### Best-of-Breed Self-Hosted Tools (Integration Targets)

| Domain | Tool | Why |
|--------|------|-----|
| **Finance** | Firefly III | Double-entry, budgets, auto-categorization rules, REST API |
| **Tasks** | Vikunja | Kanban/list/gantt, migrates from Todoist/Trello, AGPLv3 |
| **Time Tracking** | Kimai | Open-source Toggl alternative, reporting, invoicing |
| **Bookmarks** | Linkding | Full-text search, auto-fetch metadata, browser extensions |
| **Personal CRM** | Monica | Track relationships, activities, reminders, debts |
| **Documents** | Paperless-ngx | Scan, OCR, full-text search, archive |
| **Recipes** | Tandoor/Mealie | Recipe management + meal planning |
| **Monitoring** | Uptime Kuma | Status monitoring, notifications, lightweight |
| **Automation** | n8n | Self-hosted Zapier/Make, connects everything |
| **Visualization** | Grafana | Universal dashboard, any data source |
| **Inventory** | Grocy | "ERP beyond your fridge" — inventory, shopping, chores |
| **Passwords** | Vaultwarden | Self-hosted Bitwarden-compatible |

### The 8 Pillars Power Users Track

From HN threads and the Quantified Self community:

1. **Time** — Where every hour goes (deep work, meetings, leisure)
2. **Money** — Every transaction categorized, net worth over time
3. **Body** — Weight, sleep, exercise, nutrition from wearables
4. **Mind** — Mood ratings, journal entries, meditation streaks
5. **Knowledge** — Books, articles, courses, notes
6. **Relationships** — Last contacted, interaction quality, birthday reminders
7. **Projects** — Side projects, OSS, career goals, skill development
8. **Systems** — Server uptime, backup status, subscription costs

### The Hard Problem: Data Entry Friction

The most successful systems minimize manual input by:
- Automating collection (bank APIs, wearable APIs, calendar sync)
- Making daily check-ins take under 2 minutes (templated inputs)
- Using the dashboard daily as a browser homepage

### Phoenix LiveView Dashboard Architecture

Each module is a tmux "pane" — a LiveComponent with isolated state, coordinated via PubSub.

```
┌─ htop ──────────────────────┬─ tasks ─────────────────────────┐
│ Service     CPU  MEM Status │ [ ] Deploy CV v0.5.0     [!]   │
│ leptos-cv   2%   32M  ✓    │ [x] Fix Latte contrast   [done]│
│ surrealdb   5%  256M  ✓    │ [ ] Write blog post      [wip] │
│ phoenix     3%  128M  ✓    │ [ ] Update resume        [todo]│
│ ollama     45% 8.2G   ✓    │                                 │
├─ analytics ─────────────────┼─ ai ────────────────────────────┤
│ Visitors today: 47          │ houston> What did I work on     │
│ Top page: /portfolio (62%)  │          this week?             │
│ Referrer: linkedin.com (31%)│                                 │
│ ▁▂▃▅▇█▇▅▃▂▁▃▅▇ (7d trend)  │ Based on your git commits and  │
│                             │ completed tasks, you:           │
├─ journal ───────────────────┤ - Shipped CV v0.4.0             │
│ [2026-03-25] Productive day │ - Fixed 3 accessibility bugs    │
│ Mood: ████████░░ 8/10       │ - Started Phoenix dashboard     │
│ Energy: ██████░░░░ 6/10     │ - Read 2 chapters of DDIA      │
│ Sleep: 7.2 hrs (▲ 0.5)     │                                 │
└─────────────────────────────┴─────────────────────────────────┘
[houston] htop  tasks  analytics*  journal  finance  ai     14:23
```

**Key Phoenix libraries:**
- **Live Pane** — Resizable panel components (tmux-style splits)
- **ECharts via Hook** — Rich visualizations for the grafana pane
- **Contex** — Pure Elixir SVG sparklines (no JS)
- **SortableJS via Hook** — Drag-and-drop for kanban
- **CodeMirror 6 + vim mode + @catppuccin/codemirror** — Markdown editor pane
- **ExTerm** — Phoenix LiveView Terminal component for IEx-style panes
- **xterm.js** — Full terminal emulation for htop/journalctl panes
- **Oban** — Background job processing (sync, AI tasks, scheduled publishing)
- **Broadway** — High-throughput data ingestion pipelines

### Dashboard Pane Modules

| Pane | Styled As | Function |
|------|-----------|----------|
| **htop** | htop output with colored bars | Real-time service health (Leptos, SurrealDB, Phoenix, Ollama) |
| **journalctl** | Streaming log viewer | Live logs from all services, filterable by severity/service |
| **crontab** | Cron syntax table | Scheduled jobs manager (Oban), content publishing schedule |
| **vim** | CodeMirror + vim bindings | Content editor for CV, blog, notes (Markdown + live preview) |
| **ranger** | Three-column Miller layout | File/document browser for uploads, generated reports |
| **top** | Process-style table | Task manager — all active tasks with priority/deadline/status |
| **grafana** | ECharts dark-themed panels | Charts for health, productivity, finances, visitor analytics |
| **mutt** | Email-style three-pane | Notifications, messages, alerts from all integrated services |
| **ncmpcpp** | Media player UI | Content consumption tracker (reading, watching, listening) |
| **pass** | Secrets manager | Read-only reference for API keys, connection strings |
| **ai** | Terminal chat | Ollama-powered personal assistant (RAG over all data) |

---

## Appendix B: Local AI / ML Integration (Expanded)

### Hardware: RTX 3060 (12GB VRAM) + 128GB RAM

This is a serious local AI rig. The two-tier strategy: **GPU for interactive, CPU for batch.**

### What Fits on the 3060

| Model | Params | Quantization | VRAM | Speed (tok/s) |
|-------|--------|-------------|------|---------------|
| Llama 3.1 8B | 8B | Q4_K_M | ~5.5GB | 25-35 |
| Mistral 7B v0.3 | 7B | Q4_K_M | ~5GB | 30-40 |
| Phi-3 Medium | 14B | Q4_K_M | ~9GB | 12-18 |
| Qwen 2.5 14B | 14B | Q4_K_M | ~9.5GB | 10-15 |
| DeepSeek Coder V2 Lite | 16B (2.4B active MoE) | Q4_K_M | ~6GB | 25-35 |
| nomic-embed-text | 137M | F32 | ~0.5GB | Very fast |
| Whisper Medium | 769M | F32 | ~5GB | ~2x realtime |

### The 128GB RAM Unlock — CPU Inference for Big Models

| Model | Params | Quantization | RAM | Speed |
|-------|--------|-------------|-----|-------|
| Llama 3.1 70B | 70B | Q4_K_M | ~42GB | 3-8 tok/s |
| Mixtral 8x7B | 46.7B (12.9B active MoE) | Q4_K_M | ~28GB | 8-15 tok/s |
| Qwen 2.5 72B | 72B | Q4_K_M | ~44GB | 3-7 tok/s |

**Strategy:** Llama 3.1 8B on GPU for real-time chat/RAG. Llama 3.1 70B on CPU for async heavy reasoning (resume tailoring, deep analysis, batch summarization).

### Serving: Ollama (Recommended)

- REST API at `http://localhost:11434`
- Custom Modelfiles for different personas (CV chatbot, code reviewer, journal assistant)
- OpenAI-compatible API endpoint
- Concurrent model loading managed automatically
- Key env vars: `OLLAMA_NUM_PARALLEL=4`, `OLLAMA_MAX_LOADED_MODELS=3`

### Embedding + Vector Search

- **nomic-embed-text** via Ollama — 768 dims, 8K context, excellent quality
- **SurrealDB HNSW indexes** — `DEFINE INDEX idx ON table FIELDS embedding HNSW DIMENSION 768 DIST COSINE`
- **Hybrid search** — SurrealDB's `search::rrf()` combines BM25 lexical + vector cosine similarity in one query
- Alternative: Qdrant sidecar for production-grade vector search

### AI Features: Public CV

| Feature | Approach | Model |
|---------|----------|-------|
| `ask houston` chatbot | RAG over CV content | Llama 3.1 8B (GPU) |
| Smart content recommendations | Embedding similarity (no LLM needed) | nomic-embed-text |
| Natural language search | Embed query → vector search → ranked results | nomic-embed-text |
| Resume tailoring from job description | Visitor pastes JD → LLM matches relevant experience | Qwen 2.5 14B or 70B (CPU, async) |
| Auto skill assessment | GitHub activity analysis → proficiency scoring | Llama 3.1 8B |
| Blog post summarization | Batch job on publish | 70B model (CPU) |

### AI Features: Private Dashboard

| Feature | Approach | Model |
|---------|----------|-------|
| **Personal assistant** | RAG over ALL dashboard data (tasks, journal, finances, health, bookmarks) | Llama 3.1 8B (GPU) |
| **Natural language data queries** | "How much did I spend on food last month?" → LLM generates SurrealDB query | Llama 3.1 8B |
| **Smart task prioritization** | Analyze deadlines + historical patterns + energy levels | Llama 3.1 8B |
| **Expense categorization** | Embedding similarity against category prototypes | nomic-embed-text |
| **Meeting note summarization** | Whisper transcription → LLM extracts action items → auto-create tasks | Whisper + Llama 3.1 8B |
| **Voice input** | "Add a task: review the deployment pipeline" | Whisper Medium (GPU) |
| **Writing assistant** | Draft blog posts, emails, docs in your voice | Fine-tuned Llama 3.1 8B (QLoRA) |
| **Code review** | Paste code → AI feedback styled as terminal output | Qwen 2.5 Coder 7B |
| **Mood/productivity patterns** | "You're most productive on Tuesday mornings after exercise" | Statistical analysis + LLM interpretation |
| **Anomaly detection** | "Your spending on subscriptions increased 40% this month" | Time-series analysis + LLM |
| **Spaced repetition** | Optimal review intervals based on learning history | Algorithm + LLM prompts |
| **Changelog generation** | Auto-generate from git history on deploy | Llama 3.1 8B |

### Elixir/BEAM AI Integration

Bumblebee + Nx + EXLA runs on the 3060 via CUDA:
- `XLA_TARGET=cuda12` enables GPU acceleration
- `Nx.Serving` auto-batches concurrent requests under supervision tree
- Whisper speech-to-text confirmed working on RTX 3060 — official Phoenix blog post documents the 15-minute setup
- Zero-shot classification via BART-large-MNLI for auto-categorization
- Sentence embeddings via paraphrase-MiniLM-L6-v2 for semantic search
- All models can run simultaneously with 128GB RAM (BEAM processes for each)

### Fine-Tuning (QLoRA on 3060)

- **Unsloth** — 2x faster, 60% less memory. 7-8B models fit comfortably
- **Use fine-tuning for:** Writing style/voice capture (journal, emails, commit messages)
- **Use RAG for:** Factual knowledge retrieval (always current, no retraining)
- **Best combo:** RAG with a style-fine-tuned model

### The Evolution Timeline

| Phase | Timeline | What Changes |
|-------|----------|-------------|
| **RAG Foundation** | Month 1-2 | Basic chat, search, expense categorization |
| **Pattern Recognition** | Month 3-4 | Productivity patterns, financial trends, task prioritization |
| **Style Adaptation** | Month 5-6 | QLoRA fine-tune captures your writing voice |
| **Predictive Intelligence** | Month 6+ | Proactive suggestions, anomaly detection, health correlations |

**All private. All local. No data leaves your infrastructure.**

### Infrastructure Architecture

```
┌─────────────────────────────────────────────────────┐
│                    YOUR SERVER                       │
│                                                      │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────┐ │
│  │   Ollama     │  │   SurrealDB  │  │ PostgreSQL │ │
│  │ - LLM serve │  │ - Graph data │  │ + pgvector │ │
│  │ - Embeddings│  │ - CV content │  │ - Oban jobs│ │
│  │ - Whisper   │  │ - Relations  │  │ - Sessions │ │
│  └──────┬──────┘  └──────┬───────┘  └─────┬──────┘ │
│         └────────────────┼─────────────────┘        │
│                   ┌──────┴───────┐                   │
│                   │  Axum / Phx  │                   │
│                   │  Backends    │                   │
│                   └──────────────┘                   │
│                                                      │
│  GPU: RTX 3060 12GB    RAM: 128GB                   │
│  Primary LLM: ~6GB    Heavy model (CPU): ~42GB     │
│  Embeddings: ~0.5GB   Everything else: ~80GB free   │
└─────────────────────────────────────────────────────┘
```

### Key Rust Crates for AI

- `ollama-rs` — Rust client for Ollama API
- `qdrant-client` — Official Rust client for Qdrant
- `whisper-rs` — Rust bindings for whisper.cpp
- `candle` — HuggingFace's Rust ML framework
- `fastembed` — Fast embedding generation in Rust
- `tokenizers` — HuggingFace tokenizers in Rust

---

## Appendix C: SurrealDB Unified Data Model (Expanded)

### Why SurrealDB is Uniquely Suited

SurrealDB 3.0 natively supports **all** of these in one engine:
- Document store (CV content, blog posts, notes)
- Graph database (skill→project→job→income relationships)
- Relational (structured records with schemas)
- Key-value (settings, feature flags)
- Vector search (HNSW indexes for embeddings)
- Full-text search (BM25 ranking with analyzers)
- Time-series (DROP tables + materialized views)
- ML inference (SurrealML `.surml` models)
- Event triggers (DEFINE EVENT for automation)
- Computed fields (real-time derived values)
- Live queries (push changes over WebSocket)
- Changefeeds (CDC pattern for audit/sync)

### The Unified Graph — Everything Connects

```
Person:houston
  -> HAS_SKILL -> Skill:rust
    -> USED_IN -> Project:leptos_cv
      -> BUILT_AT -> Job:nicular
        -> EARNED -> Income:2024_salary
          -> FUNDED -> Expense:rent
  -> LEARNED_FROM -> Course:deep_learning
    -> RELATES_TO -> Bookmark:attention_paper
      -> TAGGED -> Tag:ml
        -> ALSO_TAGS -> Project:crypto_ml
  -> KNOWS -> Contact:colleague_jane
    -> MET_AT -> Event:rustconf_2025
  -> COMPLETED -> Task:deploy_v2
    -> PART_OF -> Goal:launch_cv
  -> TRACKED -> HealthMetric:sleep
    -> ON_DATE -> Day:2026_03_25
      -> ALSO_HAS -> MoodEntry:productive
```

### Cross-Domain Queries (All Pure SurrealQL)

```sql
-- "What skills led to my highest-paying work?"
SELECT name, ->USED_IN->project->BUILT_AT->job->EARNED->income.amount AS pay
  FROM skill ORDER BY pay DESC;

-- "What connects Rust to my crypto work?"
SELECT * FROM skill:rust->{..+shortest=project:crypto_ml};

-- "Productivity vs sleep correlation"
SELECT
  day.date,
  day.avg_sleep,
  count(day<-ON_DATE<-task WHERE status='completed') AS tasks_done
FROM day ORDER BY date DESC LIMIT 30;

-- "Related bookmarks for current project"
SELECT title, url FROM bookmark
  WHERE ->TAGGED->tag<-TAGGED<-project CONTAINS project:leptos_cv;

-- "ROI on certifications"
SELECT cert.title,
  ->VALIDATES->skill->USED_IN->project->BUILT_AT->job.salary AS enabled_salary
FROM certification AS cert;
```

### Time-Series Pattern (Health, Finance, Productivity)

```sql
-- Raw data auto-discarded after events fire
DEFINE TABLE health_raw DROP CHANGEFEED 1d;

-- Aggregated daily stats persist forever
DEFINE TABLE daily_health AS SELECT
  time::day(timestamp) AS day,
  math::mean(sleep_hours) AS avg_sleep,
  math::mean(mood) AS avg_mood,
  math::mean(energy) AS avg_energy,
  count() AS entries
FROM health_raw GROUP BY day;

-- Event: auto-embed new health entries
DEFINE EVENT embed_health ON TABLE health_raw
  WHEN $event = "CREATE"
  THEN {
    -- trigger embedding generation via HTTP to Ollama
    http::post('http://ollama:11434/api/embeddings', {
      model: 'nomic-embed-text',
      prompt: string::concat($after.notes, ' mood:', <string>$after.mood)
    });
  };
```

### SurrealDB Vector Search (Built-in)

```sql
-- Define HNSW index for semantic search
DEFINE INDEX idx_embeddings ON bookmark
  FIELDS embedding HNSW DIMENSION 768 DIST COSINE;

-- Hybrid search: BM25 + vector similarity via RRF
SELECT *, search::rrf(
  search::score(1),  -- BM25 relevance
  search::score(2)   -- vector similarity
) AS relevance
FROM bookmark
WHERE content @1@ 'distributed systems'
   OR embedding <|5,100|> $query_vector
ORDER BY relevance DESC;
```

### GraphRAG — The Ultimate Query Pattern

SurrealDB 3.0 positions itself as a single-database GraphRAG solution:

1. **Ingest:** Store documents, extract entities, build graph relationships
2. **Enrich:** Generate embeddings, compute graph metrics, link related concepts
3. **Retrieve:** Combine graph traversal + vector similarity + BM25 in one SurrealQL query

Ask your AI: "Based on my skills, projects, and learning history, what should I focus on next?" The agent queries your SurrealDB knowledge graph using GraphRAG — traversing relationships AND doing semantic search — to construct a contextually rich answer.

### Permissions: Public CV vs Private Dashboard (Same DB)

```sql
-- CV tables: anyone can read
DEFINE TABLE skill PERMISSIONS
  FOR select FULL
  FOR create, update, delete WHERE $auth.role = 'admin';

-- Dashboard tables: admin only
DEFINE TABLE health_metric PERMISSIONS
  FOR select, create, update, delete WHERE $auth.role = 'admin';

-- Mixed tables: some fields public, some private
DEFINE TABLE project PERMISSIONS FOR select FULL;
DEFINE FIELD revenue ON project PERMISSIONS
  FOR select WHERE $auth.role = 'admin';  -- hidden from public
```

### SurrealDB Features by Use Case

| Feature | Use Case |
|---------|----------|
| RELATE edges with metadata | Skill proficiency, relationship context, project contribution type |
| DEFINE EVENT | Auto-embed new content, cascade status updates, trigger notifications |
| COMPUTED fields | Skill XP scores, goal progress %, certification validity |
| DROP tables | High-frequency time-series ingestion (health, productivity) |
| Materialized views (AS SELECT) | Rolling daily/weekly/monthly aggregations |
| LIVE SELECT | Real-time dashboard updates without polling |
| Changefeeds | Audit trail, offline sync, data replay |
| HNSW vector index | Semantic search across all content |
| BM25 full-text search | Keyword search with relevance ranking |
| search::rrf() | Hybrid lexical + semantic search in one query |
| SurrealML | In-database ML inference (productivity prediction, anomaly detection) |
| Custom functions | PageRank-style skill importance, knowledge gap detection |
| Shortest path | "What connects concept A to concept B?" |
| Recursive traversal | Multi-hop graph exploration to arbitrary depth |

### Honest Limitations

1. No built-in PageRank/centrality/community detection (implement as custom functions or export to NetworkX)
2. SurrealML is inference-only (train externally, import `.surml`)
3. No mature Ecto adapter for Elixir (use `surrealix` driver directly or pair with PostgreSQL for Phoenix)
4. Bi-temporal queries not yet GA
5. Ecosystem smaller than PostgreSQL

### Pragmatic Recommendation: Dual Database

- **SurrealDB** — CV data, knowledge graph, bookmarks, relationships, vector search, time-series health data. Its graph model and multi-model nature shine here.
- **PostgreSQL + pgvector** — Phoenix dashboard sessions, Oban jobs, Ecto-backed structured data. Mature ecosystem, battle-tested.
- Both queried by the same Rust/Elixir backends. SurrealDB for the interesting graph/vector/time-series stuff, PostgreSQL for the boring-but-reliable operational stuff.

---

## Appendix D: Revised Priority Roadmap (with AI and Dashboard)

### Phase 0: Foundation
- [ ] Switch Leptos to SSR + Islands
- [ ] SurrealDB schemas + seed data
- [ ] Accessibility fixes (critical)
- [ ] Basic Kustomize manifests + Dockerfiles

### Phase 1: The Terminal CV
- [ ] Interactive terminal emulator
- [ ] CRT boot sequence with GRUB theme picker
- [ ] `man houston`, Easter eggs, virtual filesystem
- [ ] tmux status bar navigation
- [ ] Dynamic data from SurrealDB

### Phase 2: AI on the CV
- [ ] Ollama deployment (Docker + GPU)
- [ ] Embed all CV content (nomic-embed-text → SurrealDB HNSW)
- [ ] `ask houston` RAG chatbot command
- [ ] Natural language search across CV
- [ ] GitHub activity sync → auto skill assessment

### Phase 3: Dashboard MVP
- [ ] Phoenix LiveView project scaffold
- [ ] Auth (phx.gen.auth + TOTP + IAP)
- [ ] CV content manager (CRUD for SurrealDB)
- [ ] Analytics pane (page views, referrers)
- [ ] Task/goal management pane
- [ ] AI chat pane (Ollama integration via ollama-ex)

### Phase 4: Life OS
- [ ] Journal pane with mood/energy tracking
- [ ] Finance pane (Firefly III integration or custom)
- [ ] Knowledge management (bookmarks via Linkding, reading list)
- [ ] Health tracking (wearable data ingestion)
- [ ] Contact CRM pane
- [ ] Natural language queries over all data

### Phase 5: Deep AI
- [ ] Whisper voice input
- [ ] Auto expense categorization
- [ ] Smart task prioritization
- [ ] Mood/productivity pattern recognition
- [ ] QLoRA fine-tune on personal writing style
- [ ] Meeting note → action item pipeline
- [ ] Resume tailoring from pasted job descriptions

### Phase 6: Polish & Scale
- [ ] Text adventure mode
- [ ] Gamification (achievements, XP, character sheet)
- [ ] Visual effects (Matrix rain, DOOM fire, pipes)
- [ ] Sound design
- [ ] PWA with offline support
- [ ] GKE production deployment
- [ ] Skill graph visualization
