# Gate 1 — Core Loop (Workstream E) — Anime Aggressors

Branch: `cursor/gate-1-integrated-development-platform`

## Statuses
- `CORE_LOOP_IMPLEMENTED`
- `CORE_LOOP_AUTOMATED_EVIDENCE_PASS`
- `PHYSICAL_PLAYTEST_PENDING`

## Collision policy
Unity PRs #51/#52 are open. This workstream does **not** modify `unity/`.
Automated evidence uses `@anime-aggressors/game-core` (Godot production sim path).

## Run
```bash
node gate1/tools/core_loop_runner.mjs
```

## Schema
`gate1/contracts/game_core_loop.schema.json`
