# Fighter identity matrix (Wave011 runtime)

Runtime fingerprints live in `game-godot/scripts/combat/aura_identity.gd` (`AuraIdentity.PROFILES`) and are applied by `fighter.gd` / `HitResolver` — not YAML-only.

| Fighter | tag | charge_rate | air_accel | traction | charge_move | extras |
|---------|-----|-------------|-----------|----------|-------------|--------|
| ember-vale | burn_rushdown | 1.12 | 1550 | 1900 | 0.48 | trail / hitbox extend L2 |
| rook-ironside | armor_quake | 0.88 | 900 | 2400 | 0.32 | heavy armor |
| juno-spark | speed_chain | 1.20 | 1950 | 1550 | 0.55 | dash cancel |
| kaia-windrow | wind_drift | 1.05 | 2100 | 1480 | 0.50 | air drift 0.22 |
| nix-calder | freeze_control | 0.95 | 1050 | 2200 | 0.30 | ice armor L2 |
| orion-vell | gravity_pull | 0.90 | 1250 | 1850 | 0.36 | launch bias −12 |
| vesper-nyx | phase_mark | 1.08 | 1700 | 1680 | 0.44 | phase cancel |

Existing data still differentiates run speed / weight / jump. Wave011 adds air accel, ground traction, and charge-move penalty as script getters (`get_air_accel`, `get_traction`, `get_charge_move_mult`).

See also `game-godot/docs/FIGHTER_IDENTITY_MATRIX.md`.
