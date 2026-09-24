# Human Art Replacement Contract

Generated V2–V9 art from PR #106 does **not** ship. Future human artists replace
visible assets while keeping gameplay stable.

## Stable logical IDs

| ID | Pattern | Runtime meaning |
|---|---|---|
| fighter logical ID | `<fighter>` | Roster key |
| fighter mesh id | `<fighter>.mesh` | Model resolver key |
| fighter skeleton id | `<fighter>.skeleton` | Canonical deform bone set |
| fighter animation action id | `<fighter>.<action>` | Clip / Wave A action |
| sockets | see socket contract | VFX / contact anchors |
| event markers | frame-data frames | Contact, hurt, clash |
| VFX family id | `<fighter>.vfx` | Palettes + socket-aligned effects |
| resolver contract | `ACTIVE_CHARACTER_PRESENTATION` | Current visible source |

Fighter IDs: `ember-vale`, `rook-ironside`, `juno-spark`, `kaia-windrow`, `nix-calder`, `orion-vell`, `vesper-nyx`.

## Replacement path

```text
artist receives intake kit
        ↓
artist creates mesh/rig/animation
        ↓
HUMAN_CANDIDATE staging import
        ↓
contract validator
        ↓
review renders
        ↓
Godot training/review scene
        ↓
Pixel owner review
        ↓
owner sets human-quality gates
        ↓
production resolver update
        ↓
merge
```

No production replacement before owner approval.

## Gameplay must never depend on

- vertex count
- generated topology
- Blender object internals
- generator implementation
- generated material node names
- texture filenames outside the resolver contract

## Labels

Generated V2–V9 = `GENERATED_EXPERIMENT`.
Human candidates = `HUMAN_CANDIDATE` until owner approval.
Automation never sets `HUMAN_APPROVED`.

```text
HUMAN_ART_DIRECTION_APPROVAL=false
HUMAN_ANIMATION_QUALITY_PASS=false
HUMAN_COMBAT_FEEL_PASS=false
HUMAN_AURA_CLASH_PASS=false
HUMAN_CLIP_WORTHY_PASS=false
FINAL_AUTHORED_ANIMATION_PASS=false
MERGE_AUTHORIZED=false
```
