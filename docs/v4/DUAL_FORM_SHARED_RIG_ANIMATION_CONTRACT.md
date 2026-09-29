# Dual-Form Shared Rig / Animation Contract (V4)

## Invariant

```
7 GAMEPLAY IDENTITIES
14 AUTHORED BODY PRESENTATIONS
1 CANONICAL ANIMATION/RIG CONTRACT PER FIGHTER
```

Male/female meshes for the same `fighter_id` must use a compatible canonical deform skeleton.

## Required sameness (per fighter)

- same bone names (`art_source/animation/shared/deform_skeleton/CANONICAL_DEFORM_SKELETON.json`)
- same animation clip set / action IDs (`art_source/animation/fighters/<id>/actions/`)
- same root-motion assumptions (non-authoritative; CombatMath owns translation)
- same hitbox sockets
- same VFX sockets
- same weapon/effect anchors

## Allowed differences

Mesh-level proportion differences within the rig envelope.

If a visible proportion change would alter reach, **collision remains canonical** — body_variant must not gain a gameplay reach/size advantage.

## Forbidden

- Separate gameplay IDs (`rook-male`, `rook-female`) as combat authorities
- Two full animation libraries per fighter
- Importing stale PR #106 generated-art as shipping content
- Franchise costume / logo / signature pose mashups

## Runtime payload

Match setup / PartyLink carries:

```
fighter_id
body_variant   # male | female — presentation only
seat_id
team_id
```

Network authority and combat simulation **ignore** `body_variant`.
