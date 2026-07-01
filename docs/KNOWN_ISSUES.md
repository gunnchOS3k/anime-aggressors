# Known Issues — Public Demo (M5)

**Last updated:** 2026-07-01

---

## Gameplay

- Preview fighters (Nix Calder, Orion Vell, Vesper Nyx) are balance-pending — uneven vs production 4
- Energy clash / aura systems add complexity beyond minimal platform-fighter teaching
- 4-player modes blocked in UI (P3/P4 ship blocked)

## Controls

- Touch/mobile on-screen controls not implemented
- Gamepad may require button press before browser registers pad
- Keyboard P1/P2 overlap possible on single keyboard — gamepads recommended for 2P

## UI

- Career, replay vault, saved games reachable but not polished for public demo
- Custom match setup has many options — easy to misconfigure for casual players
- Some lab modes lack back-navigation polish

## Audio / VFX

- All sounds are procedural Web Audio placeholders
- VFX are simple geometry particles — not final art direction
- Shield block audio may fire on shield start, not only on block

## Performance

- Three.js procedural fighters scale with scene complexity
- Low-end GPUs may drop frames with debug overlays enabled
- Godot embed (labs) significantly heavier than main web demo

## Browser / mobile

- Mobile browsers untested for production quality
- iOS Safari audio context may need extra tap after dismiss onboarding
- No PWA/offline install flow

## Training

- Dummy modes 1–4 require keyboard number keys — not documented on mobile
- Move list overlay shows subset of moves only

## CPU

- CPU levels 1–3 functional but not tournament-grade
- CPU discovery requires custom match setup or training dummy mode 4

## Preview fighters

- Vesper Nyx projectile tuning marked preview
- Orion/Nix lack full balance pass documentation

## Engine / runtime

- TypeScript web runtime is demo stack — see ENGINE_MIGRATION_DECISION.md for limits
- Godot runtime in labs is experimental — not the production path
- No native desktop shell in M5 public demo
