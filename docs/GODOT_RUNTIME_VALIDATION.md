# Godot Runtime Validation

## Automated (repo)

| Command | Purpose |
|---------|---------|
| `npm run godot:check` | Project exists, optional CLI detection |
| `npm run godot:export:web` | Export real Web build to `apps/web/public/godot/` |
| `npm run assert:godot-export` | Fail if `dist/godot/` is placeholder or missing wasm/pck/js |
| `npm run typecheck` / `npm run test` | TypeScript shell unchanged |
| `apps/web/test/godotRoute.test.ts` | `#/godot` route wiring |
| `apps/web/test/godotExportArtifact.test.ts` | Real export artifacts + preset thread flag |
| `apps/web/test/godotRuntimeScreen.test.ts` | Error UI when export missing/placeholder |
| `apps/web/test/godotPagesPath.test.ts` | Project-site-safe paths under `/anime-aggressors/` |

## Godot editor (manual)

```bash
godot --headless --path game/godot --check-only   # if CLI available
```

Open `game/godot/project.godot` and run `Main.tscn`.

## Pages deploy validation

```bash
npm run build:pages
```

Confirms:

- [ ] `apps/web/dist/godot/index.html` exists and is not placeholder
- [ ] `apps/web/dist/godot/*.wasm` exists
- [ ] `apps/web/dist/godot/*.pck` exists
- [ ] `apps/web/dist/godot/*.js` exists
- [ ] Export uses single-threaded Web (`GODOT_THREADS_ENABLED = false` in generated html)

## Acceptance checklist

- [ ] `game/godot/project.godot` loads without errors
- [ ] Character select → battle with two fighters
- [ ] Movement, jump, double jump, dash
- [ ] Attack shows limb motion (not torso-only)
- [ ] Hit applies knockback + camera impulse
- [ ] Aura charge fills meter
- [ ] Derby requires fighter select
- [ ] Derby damages and launches dummy
- [ ] `#/godot` embed loads game (not gradient placeholder)
- [ ] Direct `/anime-aggressors/godot/index.html` loads game

See `docs/GODOT_MANUAL_QA.md` for step-by-step playtest script.
