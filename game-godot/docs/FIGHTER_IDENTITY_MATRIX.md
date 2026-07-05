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

## IP Policy

All move names are original (Cinder Rush, Faultline Breaker, Flash Circuit, etc.). No protected franchise move or character names.
