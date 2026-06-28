# Genre Gap Analysis — Anime Aggressors

## 1. Competitive references

Platform fighters in this genre (Smash-style, arena brawlers, tag fighters) generally deliver:

- Readable 2D/2.5D combat on varied stages
- Distinct roster identity per character
- Beginner-friendly inputs with advanced mastery paths
- Training, replay, and competitive rule support
- Strong audiovisual feedback on hits, supers, and stage presence

Anime Aggressors targets the same **genre shape** with original ROYGBIV elemental fighters — not a clone of any single franchise.

## 2. What Anime Aggressors already has

| Pillar | Status |
|--------|--------|
| Core combat feel | Fixed-tick sim, hitstun, shield, dodge, directional attacks, specials, supers |
| Roster identity | 7 default ROYGBIV fighters with distinct elements, sizes, move names |
| Stage identity | 8+ layouts with 3D platforms, backgrounds, flagline variants |
| Beginner onboarding | Match setup flow, combo routes, move list, training mode |
| Competitive depth | Rulesets, energy clashes, rollback session, deterministic sim |
| Training mode | Overlays, combo hints, clash prompts |
| Replay/match history | Replay recorder, career stats, match history screens |
| Progression | Career milestones, fighter stats, saved games |
| Local multiplayer | 2P input profiles, keyboard + gamepad |
| Online/rollback | Rollback package wired; netplay package exists |
| Visual spectacle | 3D low-poly fighters, VFX, 2.5D camera, contact shadows |
| Audio/presentation | SFX hooks, menu blips |
| Team modes | Flagline Clash 2v2-style mode |
| Custom rules | Ruleset editor, custom game flow |
| Accessibility | Universal move schema (no command strings) |

## 3. What the genre expects

- **Instant readability** at a glance: who is winning, who has meter, what element is active
- **Spectacle on commitment**: charging, supers, and clashes should feel earned and visible
- **Stage as character**: platforms, blast zones, and visual theme reinforce mode identity
- **Low floor, high ceiling**: two-button attack grammar + spacing/timing/aura/clash depth

## 4. Missing systems (honest)

- Ranked online ladder and matchmaking UI
- Full rollback netplay integration in shipped web client
- Dedicated replay theater with frame step for all modes
- Item/spawn systems (intentionally out of scope for core fighter)
- Full VO and licensed-style announcer pack
- Advanced DI / tech skill documentation in-game
- Stage hazards (most stages are hazard-free today)
- Cosmetic progression / skins storefront

## 5. Priority roadmap

1. **Now** — Elemental Aura Charge, HUD meter, ROYGBIV aura VFX, animation polish
2. **Next** — Energy clash 3D beams, announcer stingers, stage hazard variants
3. **Later** — Ranked netplay, spectator mode, expanded roster tools

## 6. Current pass scope

- `AuraChargeState` in game-core with Shield + Special input
- Per-element aura visual identity (7 styles)
- HUD aura meter + Super Ready badge
- Modest super/clash bonuses from aura level
- Stage visual config enrichment (title, competitive flag, prop tags)
- Fighter `auraCharging` animation state
- Training/move list aura documentation

## 7. Future pass scope

- Online ranked with ELO
- Full energy attack rendering in Three.js
- Stage hazards and competitive stage variants
- Expanded anime VFX library (screen flash, slow-mo KO)
- Creator fighter aura style overrides
