# Fighter Identity Matrix

Each fighter has a unique combat thesis expressed through move data, not shared templates.

| Fighter | Element | Combat Tag | Thesis | Signature Burst |
|---------|---------|------------|--------|-----------------|
| Ember Vale | Flame | burn_rushdown | Rushdown pressure, burn trails | Cinder Rush |
| Rook Ironside | Impact | armor_quake | Armored punishment, shockwave | Faultline Breaker |
| Juno Spark | Volt | speed_chain | Fast confirms, chain lightning | Flash Circuit |
| Kaia Windrow | Gale | wind_drift | Aerial drift, curved blades | Spiral Current |
| Nix Calder | Frost | freeze_control | Freeze control, ice traps | Glacier Lock |
| Orion Vell | Gravity | gravity_pull | Pull fields, angle manipulation | Orbit Collapse |
| Vesper Nyx | Void | phase_mark | Phase movement, delayed marks | Null Step |

## Unique Properties Per Fighter

### Ember Vale
- Element: burn
- Projectile: flame shot → flame wave → flame stream
- Aura: flame trail hitbox extension at level 2+

### Rook Ironside
- Element: quake
- Projectile: short-range shockwave (not a zoning tool)
- Aura: armor frames on heavies

### Juno Spark
- Element: chain_stun
- Projectile: fast volt needle with speed scaling
- Aura: dash cancel windows after confirm

### Kaia Windrow
- Element: wind_drift
- Projectile: curving wind blade
- Aura: improved air drift and cyclone multi-hit

### Nix Calder
- Element: chill_freeze
- Projectile: ice shard / trap at high aura
- Aura: ice armor at level 2+

### Orion Vell
- Element: gravity_pull
- Projectile: slow pull orb
- Aura: launch angle manipulation

### Vesper Nyx
- Element: void_mark
- Projectile: delayed void mark / trap
- Aura: phase cancel after selected specials

## Validation

`validate-full-scope-production.mjs` fails if fighters share identical damage, timing, projectile, throw, and aura-scaling signatures.

## Wave011 runtime fingerprints

Applied by `scripts/combat/aura_identity.gd` (not data-only):

| Fighter | charge_rate | air_accel | traction | charge_move |
|---------|-------------|-----------|----------|-------------|
| ember-vale | 1.12 | 1550 | 1900 | 0.48 |
| rook-ironside | 0.88 | 900 | 2400 | 0.32 |
| juno-spark | 1.20 | 1950 | 1550 | 0.55 |
| kaia-windrow | 1.05 | 2100 | 1480 | 0.50 |
| nix-calder | 0.95 | 1050 | 2200 | 0.30 |
| orion-vell | 0.90 | 1250 | 1850 | 0.36 |
| vesper-nyx | 1.08 | 1700 | 1680 | 0.44 |


All move names are original (Cinder Rush, Faultline Breaker, Flash Circuit, etc.). No protected franchise move or character names.
