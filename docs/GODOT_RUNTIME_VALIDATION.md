# Godot Runtime Validation

## Automated (repo)

- `npm run godot:check` — project exists, optional CLI detection
- `npm run typecheck` / `npm run test` — TypeScript shell unchanged
- `apps/web/test/godotRoute.test.ts` — `#/godot` route wiring

## Godot editor (manual)

```bash
godot --headless --path game/godot --check-only   # if CLI available
```

Open `game/godot/project.godot` and run `Main.tscn`.

## Acceptance checklist

- [ ] `game/godot/project.godot` loads without errors
- [ ] Character select → battle with two fighters
- [ ] Movement, jump, double jump, dash
- [ ] Attack shows limb motion (not torso-only)
- [ ] Hit applies knockback + camera impulse
- [ ] Aura charge fills meter
- [ ] Derby requires fighter select
- [ ] Derby damages and launches dummy

See `docs/GODOT_MANUAL_QA.md` for step-by-step playtest script.
