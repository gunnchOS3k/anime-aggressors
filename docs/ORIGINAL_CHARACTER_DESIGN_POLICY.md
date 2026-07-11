# Original Character Design Policy

Anime Aggressors may study genre-level combat grammar, timing, silhouette readability, and elemental fantasy. It must not reproduce another property's character, costume, animation sequence, move name, voice line, sound, VFX, stage layout, logo, or model.

## Reference-to-design rule

Every fighter combines at least three broad ideas and then passes an originality review. A reference is recorded as a mechanic or animation principle—such as *precision ignition*, *armored commitment*, *aerial drift*, or *delayed phase movement*—never as a request to reproduce a named character.

| Fighter | Original combat lane | Model silhouette language |
| --- | --- | --- |
| Ember Vale | Close-range heat pressure and controlled combustion | Angular ember crest and oversized asymmetric gauntlets |
| Rook Ironside | Armored reads, quake aftershocks, committed throws | Broad plated shoulders, helmet brow, heavy boots |
| Juno Spark | Speed confirms, chain arcs, short magnetized pulls | Compact frame, split bolt tufts, trailing volt scarf |
| Kaia Windrow | Air-column control, curved gusts, drift cancels | Wing sleeves and long cross-body gale sash |
| Nix Calder | Chill stacks, persistent traps, defensive terrain | Frost mantle and paired shoulder crystals |
| Orion Vell | Pull fields, orbit timing, launch-vector control | Offset gravity rings and suspended orbit nodes |
| Vesper Nyx | Phase cancels, delayed marks, misdirection | Deep hood, segmented void cape, narrow silhouette |

## Review gate

Before an asset moves from `proxy` to `authored` or `production`:

1. Compare side-by-side against [POWER_REFERENCE_LIBRARY.md](./POWER_REFERENCE_LIBRARY.md) and remove any distinctive one-to-one costume, pose, or move resemblance.
2. Verify all source files were created for this project or have a documented commercial license.
3. Require art-direction sign-off for silhouette, palette, animation arcs, and VFX language.
4. Keep the source `.blend`, exported `.glb`, generator/version metadata, and SHA-256 manifest together.
5. Keep proxy labels visible until manual animation, readability, mobile-performance, and originality reviews are signed.

The generated models in this repository are original rigged production blockouts. They establish the real 3D runtime and asset contract, but they remain visibly labeled proxies until the review gate is complete.
