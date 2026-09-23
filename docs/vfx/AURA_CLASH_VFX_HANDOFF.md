# Aura Clash VFX handoff

Data: `game-godot/data/vfx/aura_clash_slots.json`

Replace placeholder paths per fighter / slot without code changes.

Slots: startup · contact · sustained · clash · win · lose · release · residual

| Fighter | Identity (do not palette-swap a generic beam) |
|---|---|
| Ember | spiraling flame pressure / heat distortion |
| Rook | shock-pressure barrier / dense dust |
| Juno | forked electricity / rapid pulses |
| Kaia | spiral wind vortex / ribbon turbulence |
| Nix | frost pressure plane / crystalline crack |
| Orion | gravity compression lens / orbital distortion |
| Vesper | void fold / negative-space fracture |

Mixed clashes combine both identities.

Label captures `SYSTEM/VFX PLACEHOLDER — AUTHORED ACTING PENDING` until authored acting exists.

Do not mutate stage collision. Environment pulses are bounded and must clean up.
