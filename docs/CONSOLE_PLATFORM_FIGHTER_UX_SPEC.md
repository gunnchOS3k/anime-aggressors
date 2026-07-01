# Console Platform Fighter UX Specification — Anime Aggressors

**Status:** Approved UX target  
**Last updated:** 2026-07-01  
**Primary runtime:** Godot 4, `game-godot/`  
**Related:** [Product runtime pivot](./PRODUCT_RUNTIME_PIVOT.md) · [Game start flow research](./GAME_START_FLOW_MARKET_RESEARCH.md) · [Controls](./CONTROLS.md)

---

## Purpose

This document defines the **player-facing interaction model** for Anime Aggressors as a local, offline platform fighter with **controller-first, console-style flow**. It adopts structural principles common to modern platform fighters on Nintendo Switch and similar consoles — **without copying Nintendo, Super Smash Bros., or any third-party trade dress, assets, logos, sounds, fonts, or UI art**.

Anime Aggressors maintains **original branding**: elemental ROYGBIV identity, fighter silhouettes, stage naming, typography, color palette, and audio direction defined in production docs.

**Reference only:** mode ordering, grid selects, ready gates, versus beat, readable HUD — not visual cloning.

---

## Design principles

| Principle | Implementation |
|-----------|----------------|
| **Controller first** | Every screen navigable with D-pad/stick + face buttons; mouse/keyboard secondary |
| **Large targets** | Tile and panel hit areas sized for TV and handheld legibility |
| **Strong focus** | Clear outline/glow on focused item; no ambiguous selection |
| **Button prompts** | Contextual A/B/X/Y (or platform equivalents) in footer |
| **No dead ends** | Back always available; cancel returns to known parent |
| **Ready gates** | Battle does not start until setup confirmed |
| **Readable combat** | HUD damage, stocks, and names legible at 1080p and scaled handheld |
| **Honest scope** | Disabled modes grayed with explanation, not fake toggles |
| **16:9 first** | Layout safe zones for 1920×1080; scalable UI anchors |

---

## Global navigation

### Input conventions (Godot default map)

| Action | Gamepad | Keyboard fallback |
|--------|---------|-------------------|
| Confirm | A / Cross | Enter / Z |
| Back / Cancel | B / Circle | Escape / X |
| Tab next panel | RB / R1 | Tab |
| Tab prev panel | LB / L1 | Shift+Tab |
| Ready (hold) | A hold at select | Enter hold |

Exact bindings live in `game-godot` input map and [CONTROLS.md](./CONTROLS.md).

### Footer pattern

Every menu screen includes:

- **Left:** Back prompt (`B` — Back)
- **Center:** Context hint (e.g., “Choose your fighter”)
- **Right:** Confirm prompt when applicable (`A` — Confirm)

### Transition pattern

- **Fade or slide** between major scenes (≤ 400 ms)
- **Audio sting** on confirm (original AA SFX only)
- **No gameplay sim** running behind full-screen menus

---

## Flow overview

```text
Boot → Main Menu
         ├─ Start Battle → Mode (if needed) → Ruleset → Fighter Select → Stage Select → Ready → Versus → Countdown → Battle → Results
         ├─ Training → Fighter Select → Training Stage → Battle (training rules)
         ├─ Rulesets (library)
         ├─ Fighter Vault (read-only codex)
         ├─ Stage Vault (read-only codex)
         ├─ Controls
         ├─ Settings
         └─ Labs (experimental; visually separated)
```

---

## Main menu

### Layout

- **Hero region:** Anime Aggressors logo + subtle elemental arena background (original art)
- **Primary tile row:** Large selectable tiles (minimum 280×120 px at 1080p reference)
- **Secondary row:** Smaller tiles for vaults, controls, settings
- **Labs strip:** Bottom or side column, reduced saturation, “Experimental” label
- **Status/footer:** Build version, input device detected, hint text

### Tiles

| Tile | Priority | Action |
|------|----------|--------|
| **Start Battle** | Primary (default focus) | Enters battle setup flow |
| **Training** | Secondary | Training mode setup |
| **Rulesets** | Secondary | Ruleset library |
| **Fighter Vault** | Tertiary | Fighter codex |
| **Stage Vault** | Tertiary | Stage codex |
| **Controls** | Tertiary | Binding reference + remap entry |
| **Settings** | Tertiary | Audio, display, accessibility |
| **Labs** | Quaternary | Derby, prototypes, web legacy links |

### Controller behavior

- Initial focus: **Start Battle**
- D-pad/stick moves between tiles with wrap
- A confirms; B exits application (with confirm dialog)

### Visual identity

- ROYGBIV accent on focus ring
- Fighter idle silhouettes or aura particles in background — **original characters only**

---

## Battle setup

Sequential setup before any battle sim runs. Guards prevent skipping required steps.

### Mode select (when multiple modes ship)

| Mode | Description |
|------|-------------|
| **Stock** | Default local versus |
| **Time** | Timer + score |
| **Training** | Routed from main menu Training tile (may skip this screen) |

Future modes (Flagline, Derby) launch from **Labs** until promoted to primary menu.

### Ruleset select

See [Rulesets](#rulesets) section. Summary shown on continue.

### Fighter select

See [Fighter select](#fighter-select).

### Stage select

See [Stage select](#stage-select).

### Ready check

- Summary panel: mode, rules, P1 fighter, P2/CPU fighter, stage
- Both human players press **Ready** (or single confirm for CPU match)
- Edit shortcuts: jump back to fighter or stage select

### Versus splash

- Split screen: P1 portrait/name vs P2/CPU portrait/name
- Stage name subtitle
- Short sting + particle burst (original VFX)
- Auto-advance after 2–3 s or A to skip

### Countdown

- **3 → 2 → 1 → FIGHT!** (original typography and VO/SFX)
- Inputs **disabled** until FIGHT displays
- Camera settles on spawn positions

---

## Fighter select

### Layout

```
┌─────────────────────────────────────────────────────────┐
│  [P1 Panel]              [Fighter Grid 7]     [P2 Panel] │
│  portrait                all roster           portrait   │
│  name                    4×2 or scroll        name       │
│  archetype                                     CPU ▼    │
│  element                                       level ▼  │
│  stats mini                                    ready ☐  │
│  move preview strip                                       │
└─────────────────────────────────────────────────────────┘
│  Footer: B Back    ·    Choose fighter    ·    A Confirm │
└─────────────────────────────────────────────────────────┘
```

### Roster (all seven)

| ID | Display name | Archetype | Element |
|----|--------------|-----------|---------|
| `ember-vale` | Ember Vale | All-rounder | Fire |
| `rook-ironside` | Rook Ironside | Bruiser | Earth |
| `juno-spark` | Juno Spark | Rushdown | Lightning |
| `kaia-windrow` | Kaia Windrow | Acrobat | Wind |
| `nix-calder` | Nix Calder | Zoner | Water |
| `orion-vell` | Orion Vell | Sword | Light |
| `vesper-nyx` | Vesper Nyx | Trickster | Shadow |

### P1 panel

- Portrait placeholder (color + silhouette until art lands)
- Name, archetype, element tag
- Weight/speed/jump/recovery bars (normalized 1–10)
- Signature move name
- Move preview: idle cycle or move list carousel

### P2 / CPU panel

- Same detail as P1 when human
- **CPU toggle:** Human vs CPU
- **CPU level:** 1–9 (1 = passive, 9 = aggressive); default 3
- Ready checkbox / hold-to-ready

### Grid interaction

- Focus moves grid cursor; A assigns fighter to active player slot
- LB/RB switches active player (P1 ↔ P2)
- Duplicate fighter allowed (mirror match) unless rules forbid

### Ready state

- Each active slot must show **Ready**
- Continue enabled when all slots ready
- B returns to main menu or previous setup step per stack

---

## Stage select

### Layout

- **Grid/cards** of production stages with preview thumbnail
- **Random** tile (dice icon, original art)
- **Rules summary** sidebar: stocks, time, hazards on/off
- Focus + confirm pattern consistent with fighter select

### Production stages (baseline)

| ID | Display name | Layout type |
|----|--------------|-------------|
| `skyline-arena` | Skyline Arena | Three-platform |
| `training-grid` | Training Grid | Flat training |
| `impact-platform` | Impact Platform | Single main |
| `center-clash` | Center Clash | Symmetric platforms |
| `lunar-outpost` | Lunar Outpost | Production |
| `solar-outpost` | Solar Outpost | Production |

Additional stages from `game-godot/data/stages/` as catalog grows.

### Stage card contents

- Preview placeholder or render
- Display name
- Layout type label (Flat, Platforms, Training)
- Hazards badge if applicable

### Random stage

- Picks from legal stage list for current ruleset
- Shows resolved stage on confirm before versus

### Navigation

- B → Fighter select
- A → Ready check (or Versus if ready gate combined)

---

## Rulesets

### Screen structure

- **Preset list:** Stock (default), Time, Stamina (if implemented)
- **Custom rules** editor
- **Recent rulesets** (last 5 local)
- **Save ruleset** / **Create ruleset**

### Rule fields

| Field | Options | Notes |
|-------|---------|-------|
| **Stock count** | 1–99 | Default 3 |
| **Time limit** | Off, 2:00, 5:00, custom | Time mode |
| **Stamina** | On/Off | Only if stamina damage model ships |
| **CPU level** | 1–9 | Default for CPU slots |
| **Team attack** | On/Off | Future teams |
| **Hazards** | On/Off | Per-stage support |
| **Items/spirits** | **Disabled** | Grayed unless implemented |

### Persistence

- Godot `user://` save for rulesets in primary runtime
- Do not assume web `localStorage` rulesets apply to Godot

### Actions

- **Save ruleset** — name + persist
- **Create ruleset** — duplicate preset and edit
- **Recent** — quick recall

---

## Battle HUD

### In-match elements

| Element | Position | Content |
|---------|----------|---------|
| **P1 badge** | Top-left | Name, damage %, stock icons |
| **P2 badge** | Top-right | Name, damage %, stock icons; CPU icon if CPU |
| **Timer** | Top-center | Countdown in time mode |
| **Center message** | Center | Countdown, FIGHT!, sudden death |
| **KO callout** | Center | “KO!” + victim name (original styling) |

### Damage display

- Integer percent, large tabular figures
- Color shift at high percent (original palette, not Smash purple clone)

### Stocks

- Icon per stock remaining; lost stock animates out

### Shield / stun feedback

- Shield crack overlay on fighter
- Stun stars or swirl (original VFX) when applicable

### Pause overlay

- **Resume**
- **Controls reference**
- **Restart match**
- **Return to main menu**

Pause freezes sim; audio ducking.

---

## Results

### Layout

- **Winner banner** — name + portrait
- **Stats table** (when available): KOs, falls, damage dealt
- **Action row** — large tiles

### Actions

| Action | Behavior |
|--------|----------|
| **Rematch** | Same fighters, stage, rules → Versus → Battle |
| **Change fighters** | → Fighter select (rules + stage kept) |
| **Change stage** | → Stage select |
| **Back home** | → Main menu |

### Loop

- No automatic return; player chooses next action
- B from results → Main menu with confirm if match in progress (N/A at results)

---

## Training mode

Flow: **Main Menu → Training → Fighter Select (P1 only) → Training Grid → Battle**

Training rules:

- Damage reset button
- Spawn CPU dummy (passive by default)
- Optional: hitbox overlay, input display (when implemented)
- Exit via pause → main menu

---

## Settings

| Category | Options |
|----------|---------|
| **Audio** | Master, SFX, music sliders; mute |
| **Display** | Fullscreen, resolution (desktop), screen shake intensity |
| **Accessibility** | Reduced motion, high-contrast HUD |
| **Language** | English first; i18n hooks for later |

B returns to main menu.

---

## Controls screen

- Visual diagram of gamepad + keyboard
- Per-player profile list (P1–P4 when supported)
- Remap flow: select action → press button → confirm
- Reset to defaults

---

## Fighter vault & stage vault

Read-only codex for lore, stats, and move lists — **not** required to start battle.

- Grid browse
- Detail page per entry
- B returns to main menu

---

## Labs (experimental)

Visually separated from primary tiles:

- Impact Dummy Derby (when enabled)
- Legacy web runtime link (opens labeled web view)
- Edge-IO / netplay experiments
- Debug scenes

Footer warning: *“Experimental — not part of primary game balance.”*

---

## Accessibility

- Focus order matches visual layout
- Minimum 4.5:1 contrast on HUD text
- Reduced motion: shorten or disable menu transitions and camera shake
- Scalable UI scale factor in settings (0.85–1.25)

---

## IP and branding compliance

| Allowed | Not allowed |
|---------|-------------|
| Original Anime Aggressors logos, fighters, stages, SFX | Nintendo / Smash logos, fonts, UI skins |
| Industry-standard flow (select → ready → fight) | Copied menu layouts that mimic Smash trade dress |
| Generic terms: Stock, Time, Training | Character names, stage names, or art from Smash |
| Original button prompt *style* | Exact Smash prompt icons or colors implying affiliation |

Store reference screenshots outside the repo if needed for team discussion; **do not commit** Nintendo copyrighted materials.

---

## Acceptance checklist (UX)

| ID | Criterion |
|----|-----------|
| UX-01 | Main menu reachable with controller only from boot |
| UX-02 | Start Battle completes full setup without mouse |
| UX-03 | Fighter grid shows all seven fighters with P1/P2 panels |
| UX-04 | Stage grid shows production stages + random |
| UX-05 | Ready gate blocks battle until confirmed |
| UX-06 | Versus splash and countdown play before inputs enable |
| UX-07 | HUD shows name, damage %, stocks for all players |
| UX-08 | Pause offers resume, restart, home |
| UX-09 | Results offers rematch, change fighters/stage, home |
| UX-10 | Labs visually distinct; legacy web link labeled |
| UX-11 | No Nintendo/Smash assets in UI textures or audio |

---

## Implementation ownership

| Area | Owner |
|------|-------|
| Scene graph & navigation | Godot engineering |
| UI theme & focus | Godot + art direction |
| Input map | Godot engineering |
| Copy & naming | Game design / narrative |
| Fighter & stage data | Design + engineering (shared JSON) |

This spec is the **authoritative UX target** for Godot work. Web legacy flows may diverge until Phase 4 deprecation.
