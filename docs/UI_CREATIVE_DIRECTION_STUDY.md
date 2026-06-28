# UI Creative Direction Study — Anime Aggressors

## 1. What a main menu does emotionally

A main menu is the player's first contract with the game. Before any tutorial or match, it answers: *what kind of experience am I entering?* Fighting games especially must communicate energy, rivalry, and spectacle. A flat list of links feels like documentation; a living arena feels like a fighter is waiting.

## 2. What a main menu does functionally

Functionally, the menu must route players to modes quickly, surface the default play path, and tuck advanced or debug tools out of the primary sightline. It must work with mouse, keyboard, and controller without requiring the player to read paragraphs.

## 3. Common game menu formulas

Most commercial games converge on a few formulas:

- **Title splash → primary CTA → mode list** (arcade clarity)
- **Character on screen + mode rail** (roster-first fighters)
- **3D hub you can eventually walk** (RPG / live-service)
- **Minimal black + logo + one button** (prestige / cinematic)

Each formula optimizes for a different fantasy: immediacy, identity, exploration, or restraint.

## 4. Unorthodox game menu choices

Some teams deliberately break convention:

- **Physical-space menus** (desk, cockpit, train car) — immersion over speed
- **Diegetic UI** (in-world screens, NPC terminals) — world-building cost
- **Single-button auto-continue** — speedrun / roguelike loops
- **Hidden debug behind gestures** — ship fast, document later

Unorthodox menus work when the audience expects exploration; they fail when the player just wants to rematch in ten seconds.

## 5. Why creative directors choose physical-space menus

Physical-space menus (desks, shelves, arcade cabinets) give art direction a tangible metaphor. Props carry story without exposition. The tradeoff is navigation complexity and accessibility — not every player reads spatial affordances the same way.

## 6. Why some games choose minimalist menus

Minimalist cinematic menus reduce cognitive load and keep focus on a key visual (logo, character silhouette, one CTA). They age well in trailers and work on consoles. The risk is feeling empty if the background does not carry enough identity.

## 7. Why fighting games emphasize character, mode, and immediacy

Platform fighters sell **character fantasy** and **competitive readability**. Players expect to see fighters, elements, stages, or modes at a glance. Secondary systems (training, replays, labs) matter but should not compete with "Start Match."

## 8. Wireframe lifecycle from concept to final UI

Typical studio flow:

1. Player fantasy statement
2. First-5-seconds readability test
3. Information architecture (primary / secondary / meta / debug)
4. Low-fidelity wireframe (layout only)
5. Motion wireframe (what moves, what pulses)
6. Controller navigation prototype
7. Visual identity pass (type, color, VFX)
8. Usability pass (can a new player start a match?)
9. Accessibility pass (focus order, contrast, reduced motion)
10. Build integration
11. Playtest feedback
12. Final polish

## 9. Anime Aggressors menu design principles

- **Elemental Arena Hub** — the menu is a living 2.5D arena, not a dashboard
- **One primary CTA** — Start Match dominates
- **ROYGBIV identity** — aura and fighters visible before gameplay
- **Beginner-first** — no command strings on the home screen
- **Honest hierarchy** — labs/debug are present but visually secondary
- **Hash routes preserved** — GitHub Pages safe navigation

## 10. Final selected direction

### Menu archetypes considered

| Archetype | Fit for Anime Aggressors |
|-----------|--------------------------|
| A. Button dashboard | Current state — functional, not game-like |
| B. Title screen + mode list | Good baseline; needs spectacle |
| C. Living hub / diorama | **Selected core** |
| D. Character showcase | Integrated via fighter idle models |
| E. Physical desk/object menu | Too slow for quick rematch loop |
| F. Arcade cabinet menu | Tone reference, not full metaphor |
| G. Mission control / cockpit | Wrong genre signal |
| H. Minimal cinematic menu | Too empty without fighters |

### Selected: Elemental Arena Hub

The main menu is a **living 2.5D arena scene** where fighters idle, elemental aura particles drift, stage lighting sweeps, and modes are grouped by importance. Start Match is the hero action; labs live in a subdued footer region.

This direction sells *anime platform fighter* immediately while preserving all existing routes and flows.
