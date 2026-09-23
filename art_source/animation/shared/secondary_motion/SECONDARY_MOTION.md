# Secondary Motion Architecture

**This pass:** contract + bone names + runtime hook points. **Not** human-authored hair/cloth.

`AUTHORED_SECONDARY` / `POSE_BIBLE` / `HURT` / `CHARGE` quality gates stay **false**.

## Intent

Secondary motion (hair, coat, cape, skirt, cloth, props) must read identity without fighting gameplay.

- Gameplay skeleton remains stable.
- Secondary bones are optional deform or runtime spring — never authoritative locomotion.
- Authored secondary is a later human pass. Runtime spring is a **fallback**, labeled `PROCEDURAL_FALLBACK`.

## Bone prefix contract

| Prefix | Use |
|--------|-----|
| `Hair_` | Head-child chains |
| `Cape_` / `Coat_` | Chest / back-child |
| `Skirt_` | Hips-child |
| `Cloth_` | Generic |
| `Prop_` | Held weapons / fans — sockets preferred |

## Runtime

`SecondaryMotionLayer` (Godot) may apply light spring follow on optional bones when:

- authored secondary clip is `MISSING`
- accessibility reduce-motion is **off**
- the bone exists on the live skeleton

It must not:

- write root translation
- change hitboxes
- claim authored secondary quality

## Per-fighter notes (handoff, not done)

| Fighter | Authored secondary needed |
|---------|---------------------------|
| Ember Vale | Coat hem + flame-hair flicker |
| Rook Ironside | Coat plates / pauldron settle |
| Juno Spark | Short hair snap + jacket pop |
| Kaia Windrow | Long coat / hair carry-arcs |
| Nix Calder | Collar / crystal dangles (stiff) |
| Orion Vell | Heavy coat delay |
| Vesper Nyx | Asymmetric scarf / void hem |
