# PR #118 Playable Runtime Preflight Map (V1.3)

## Live head
- PR: #118 draft `v4/dual-form-power-roster`
- Verified at discovery time against live worktree tip.

## Canonical runtimes
| Surface | Path | Role |
|---|---|---|
| Browser/desktop gameplay | `apps/web` + `packages/game-core` | Primary product UX (Vite/Three.js) |
| Simulation | `packages/game-core` | Deterministic combat, moves, career |
| Renderer | `apps/web/src/renderer-three` | Low-poly humanoid battle models |
| Model factory | `apps/web/src/renderer-three/fighters/FighterModelFactory.ts` | Builds procedural humanoid from appearance (not GLB yet) |
| Animation | `apps/web/src/renderer-three/fighters/FighterAnimationController.ts` + Godot `fighter_animation_controller.gd` | Pose/clip application |
| Godot product path | `game-godot/` | Android/export + PartyLink/RC harnesses |
| Asset resolver | `game-godot/scripts/visual/fighter_asset_resolver.gd` | GLB + body_variant presentation paths |
| Save/career | `apps/web/src/storage/*`, `packages/game-core/src/career/*` | Match history / career milestones |
| Story (pre-V1.3) | career milestones only — no seven-route campaign engine | Gap closed by V1.3 story module |
| PartyLink | `packages/partylink`, `packages/rollback` | Preserve interfaces |
| Android | `game-godot` export presets + `apps/mobile` | Exact-head APK via Godot export when possible |

## Representative body-variant chain (Ember Female)
1. Character select stores `bodyVariant: "female"` (`characterSelectState.ts`).
2. Match setup writes `config.bodyVariants[]` (`matchSetupSession.ts`).
3. Battle renderer previously resolved appearance by fighter id/color only — **body variant did not change battle mesh**.
4. Godot resolver has `body_variant_presentation_path(fighter, variant, role)` under `art_source/characters/<id>/<male|female>/<role>/`.
5. V1.3 wires body variant into appearance + diagnostics so female Ember is distinguishable in battle and Godot loads variant presentation when assets exist.

## Animation authority
- Spectrum: 777 AUTOMATION_AUTHORED_CANDIDATE clips under `content/fighters/<id>/animations/procedural/`.
- Yin/Yang: fighter JSON + moves exist as TUNING_CANDIDATE; not in `roster.json` pre-V1.3; animation slots produced in this run.
