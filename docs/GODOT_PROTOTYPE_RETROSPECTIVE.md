# Godot Prototype Retrospective

**Scope:** PR #45 – PR #48 on `game-godot/`

---

## What worked

- Godot-first folder structure and data normalization (7 fighters, move manifests)
- TypeScript demotion to validation/oracle
- Training/debug scaffolding concepts
- Automated npm validation and smoke test scripts
- Honest blocker docs (final art, signed playtest)

---

## What did not work

- **Reliable combat in Play** — human playtests showed hits, feel, and loop still broken or unsatisfying despite passing validators
- **Architecture recursion** — large doc/validation passes outpaced playable improvement
- **Proxy-only visuals** masked whether systems were fun; validators could not measure satisfaction
- **Godot CLI often absent** on dev/CI machines — editor signoff remained open

---

## Lessons

1. Passing repo gates ≠ playable fighter
2. Status JSON must not substitute for editor playtest evidence
3. Smaller engine-native proof scenes beat full-scope consolidation when combat is unproven
4. Freeze prototypes instead of endless patch chains when the loop fails human test

---

## Disposition

`game-godot/` is **frozen, not deleted**. It remains reference for data shapes, move IDs, and menu flow ideas.

New gameplay proof target: **Unity combat spike** (`unity/AnimeAggressorsUnity/`).
