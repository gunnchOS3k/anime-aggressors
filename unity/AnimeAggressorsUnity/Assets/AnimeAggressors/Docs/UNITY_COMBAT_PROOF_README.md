# Unity Combat Proof — Anime Aggressors

**Status:** Proof spike — not production runtime  
**Target editor:** Unity 6 LTS (`6000.0.23f1` or newer 6000.x)  
**Scene:** `Assets/AnimeAggressors/Scenes/CombatProof.unity`

---

## Setup (Unity not detected on CI agent)

1. Install **Unity Hub** + **Unity 6 LTS**
2. Open Hub → Add → select `unity/AnimeAggressorsUnity/`
3. Open project; allow script compile
4. Open `Assets/AnimeAggressors/Scenes/CombatProof.unity` (or any scene — bootstrap auto-builds on Play)
5. Press **Play**

If CombatProof scene is empty, `CombatProofBootstrap` still runs via `RuntimeInitializeOnLoadMethod` and builds platform, fighters, camera, HUD.

---

## Controls (keyboard — legacy Input)

| Key | Action |
|-----|--------|
| A / D | Move |
| Shift (hold) | Run |
| W | Jump / double jump |
| S | Fast fall (airborne) |
| J | Jab |
| H | Heavy |
| K | Special |
| L | Shield hold |
| U | Grab (J or U while holding: throw) |
| I | Dodge |
| K + L | Aura charge |
| J (at 100% aura) | Aura burst |
| B | Toggle dummy shield |
| R | Reset fighters |
| F1 | Toggle debug HUD |
| F2 | Toggle hitbox viz |
| F6 | Toggle hurtbox viz |
| Esc | Pause / resume |

**Gamepad:** Not wired in this spike — use Input System package in follow-up if proof passes.

---

## Proof gate (human Play Mode)

See `docs/UNITY_SPIKE_ACCEPTANCE_CHECKLIST.md`.

---

## Architecture

Single-scene, runtime-built proof. No menus, no roster export, no web build.

Scripts live in `Assets/AnimeAggressors/Scripts/`. Move data: `Data/default_moves.json` + `Resources/default_moves.json`.

---

## Visuals

Proxy capsules/cubes — **PROXY, not final art**.

---

## Godot

Frozen historical prototype — see `docs/ENGINE_RESET_DECISION.md`. Do not patch Godot as main path until Unity proof gate passes.
