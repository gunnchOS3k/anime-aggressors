# Production Acceptance Gates

A feature is **not done** because files exist. It is done when it passes the gate for its milestone.

## Global gates (every PR touching Godot gameplay)

- [ ] `npm run validate:godot-product` passes
- [ ] `npm run build:pages` passes
- [ ] No public screen presents DEBUG FALLBACK as final without label
- [ ] Fighter spec updated if move/silhouette changed
- [ ] Playtest note or screenshot in PR when visual combat changes

## M2 — One production fighter pipeline

- [ ] One fighter has `.blend` source + `.glb` in exports
- [ ] `FighterAssetContract.validate()` passes for that fighter
- [ ] At least idle, walk, neutral_attack clips authored
- [ ] Hitbox follows hand socket in playtest

## M3 — Two production fighters

- [ ] Two fighters pass asset contract
- [ ] Full locomotion + attack set for both

## M4 — Complete match loop

- [ ] Title → mode → select → stage → versus → battle → winner (no debug skip)
- [ ] Skyline Arena (or selected stage) production art pass started

## M6 — Full roster

- [ ] All seven fighters pass spec + asset contract OR explicit WIP with gate failure documented

## CI enforcement

`scripts/validate-godot-product-quality.mjs` enforces infrastructure gates (specs, scenes, contract files, manifest). Art beauty is manual QA; **debug-as-final is blocked in CI**.
