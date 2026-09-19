# VXP-2 — Anime Aggressors Brand System & Match Presentation

Owner: Edmund Gunn Jr. / gunnchOS3k  
Program: gunnchOS Visual Experience & Product Delight (VXP)

## Design direction

**AURA FORGE** is a design-system label only. The player-facing game name remains **Anime Aggressors**.

## What shipped

- Original brand assets under `game-godot/assets/branding/vxp2/` (+ `BRAND_PROVENANCE.json`)
- Production theme `game-godot/assets/ui/themes/aa_vxp2_theme.tres` (legacy `aa_theme.tres` preserved)
- Main menu hero + **FIGHT** primary CTA; Labs/Mobile Playtest demoted
- Fighter / stage / versus / results presentation polish
- Touch/controller glyph foundation
- Battle HUD chrome alignment
- Accessibility visual treatment hooks (reduce motion, high contrast, non-color cues)
- Screenshot harness + structural gates

## Honesty

- No physical Pixel capture claimed
- No human visual/fun validation claimed
- Historical launcher/splash icons remain **UNRESOLVED_PROVENANCE**
- Do not merge without owner authorization

## Run

```bash
make vxp2-structural
make vxp2-capture
make vxp2-gates
```
