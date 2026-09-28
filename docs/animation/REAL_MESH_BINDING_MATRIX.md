# Real mesh binding matrix

Current fighter visuals are **procedural / proxy**, not final character art.

| Fighter | Runtime mesh | Topology | Materials | Skeleton binding | Blend shapes | Secondary | Authored source |
|---|---|---|---|---|---|---|---|
| ember-vale | `procedural_final/ember-vale.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| rook-ironside | `procedural_final/rook-ironside.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| juno-spark | `procedural_final/juno-spark.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| kaia-windrow | `procedural_final/kaia-windrow.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| nix-calder | `procedural_final/nix-calder.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| orion-vell | `procedural_final/orion-vell.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |
| vesper-nyx | `procedural_final/vesper-nyx.glb` | procedural | low | runtime procedural map | none | fallback springs | master blend = proxy cylinder |

Automatic binding of the procedural GLB onto the canonical deform skeleton is **not safe**
(different topology, auto-weights will break shoulders/hips).

`MESH_BINDING_NEEDS_HUMAN_WEIGHT_PAINT=true`

Authored proof GLBs use a skinned cylinder for import-path proof only.
