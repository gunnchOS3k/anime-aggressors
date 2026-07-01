# Playtest Evidence Guide

Capture proof for manual Godot editor verification. Large videos do not need to be committed.

---

## Where to put evidence

| Option | When to use |
|--------|-------------|
| `playtest-evidence/` (local, gitignored large files) | Developer machine captures |
| GitHub PR attachments | PR #48+ review |
| Small GIFs in `playtest-evidence/` | OK if under ~5 MB each |
| External unlisted link | Long sessions; paste URL in signoff file |

List filenames or URLs in your signoff copy under `docs/manual-playtests/`.

---

## Required captures (14)

1. **Boot → Main Menu** — screenshot after F5
2. **Training spawn** — both fighters on stage
3. **Debug HUD** — state + move frame visible (F1)
4. **Hitbox/hurtbox overlay** — F2/F6 enabled
5. **Jab hit in range** — damage % increased + hit log
6. **Jab miss out of range** — no damage change
7. **Shield block / shield stun** — SHIELD in log or visible stun
8. **Grab success** — GRAB success in log/HUD
9. **Throw** — knockback + damage change
10. **Aura charge** — meter + VFX visible
11. **Aura burst** — meter consumed + hit effect
12. **KO + respawn** — stock down, respawn i-frames if applicable
13. **Results screen** — winner shown
14. **Rematch** — back to countdown/battle

---

## Naming convention

```text
playtest-evidence/YYYY-MM-DD-<tester>-<topic>.png
playtest-evidence/YYYY-MM-DD-<tester>-training-hud.gif
```

---

## Automated evidence (no screenshot needed)

- `tmp/aa-verify-project-report.json` — npm + Godot CLI results
- `docs/PR48_VERIFICATION_REPORT.md` — human-readable summary

These do **not** replace editor playtest signoff.

---

## Checklist cross-reference

- Training items: `docs/GODOT_EDITOR_PLAYTEST_SIGNOFF.md`
- Versus items: same
- Acceptance detail: `docs/TRAINING_ACCEPTANCE_TESTS.md`, `docs/VERSUS_ACCEPTANCE_TESTS.md`
