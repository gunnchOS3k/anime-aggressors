# Godot Manual QA

## Normal Battle

1. Open Godot project or web export
2. Click **Normal Battle** on mode bar (if visible) or use character select flow
3. Select **Ember Vale** (P1) and **Juno Spark** (P2)
4. Click **Start Battle**
5. **Move** — P1 A/D, P2 arrows
6. **Jump** — W/Space and Up/Numpad0
7. **Double jump** — press jump again in air
8. **Attack** — J / Numpad1 — confirm arm swings
9. **Special** — K / Numpad2
10. **Aura** — hold F / Slash — meter fills, glow intensifies
11. **Hit opponent** — confirm hitstop feel, knockback, victim flinch
12. **Camera** — frames both fighters, small punch on heavy hit

## Impact Dummy Derby

1. Click **Impact Dummy Derby** on mode bar
2. Confirm character select appears (**Choose Your Derby Fighter**)
3. Select a fighter → **Continue to Derby**
4. Confirm dummy and runway visible
5. Damage dummy during timer phase
6. Use Kinetic Bat for final launch
7. Confirm distance/score results

## Web launcher (`#/godot`)

1. `npm run dev` → open `#/godot`
2. Confirm embed or export instructions
3. After `npm run godot:export:web`, iframe loads game
