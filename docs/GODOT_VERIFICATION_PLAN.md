# Godot Verification Plan (PR #48)

**Runtime:** Godot 4.2+ — `game-godot/`  
**Policy:** Proof over claims — status JSON alone does not verify runtime.

---

## What can be verified automatically (npm / Node)

| Check | Tool |
|-------|------|
| Fighter/move JSON schema | `validate:full-scope-production` |
| Required scenes exist | `validate:full-scope-production` |
| Scene script paths resolve | `validate:full-scope-production` |
| P1/P2 InputMap parity | `validate:full-scope-production` |
| PR #47 runtime hardening gates | `validate:full-scope-production` |
| TypeScript typecheck | `npm run typecheck` |
| Workspace unit tests | `npm run test:workspaces` |
| Web/packages build | `npm run build` |
| Recursive verify orchestration | `node scripts/aa-verify-project.mjs` |

**Tier label:** `automated_npm: verified` when all npm gates pass.

---

## What needs Godot CLI

| Check | Command |
|-------|---------|
| Project import / boot | `godot --path game-godot --headless --quit-after 1` |
| Smoke suites | `godot --path game-godot --headless -s res://tests/smoke_runner.gd` |

Detects: `godot4`, `godot`, `/Applications/Godot.app/...`, `GODOT_BIN` env.

If CLI missing → **`GODOT_CLI_MISSING — manual editor signoff required`** (does not fail npm CI by default).

**Tier label:** `godot_cli: verified` only when import + smoke_runner pass.

---

## What needs Godot editor (human)

| Check | Document |
|-------|----------|
| F5 play from BootScene | `GODOT_EDITOR_PLAYTEST_SIGNOFF.md` |
| Training combat acceptance | same + `TRAINING_ACCEPTANCE_TESTS.md` |
| Versus flow acceptance | same + `VERSUS_ACCEPTANCE_TESTS.md` |
| Visual evidence capture | `PLAYTEST_EVIDENCE_GUIDE.md` |

**Tier label:** `godot_editor_playtest: manual_signoff_required` until a filled signoff file exists in `docs/manual-playtests/`.

---

## What remains final-art blocked

- Authored `.glb` fighter meshes
- Final Blender animation clips (proxy runtime may pass smoke tests)
- Final SFX/VFX mix
- Tournament balance pass

**Tier label:** `final_art: blocked`

---

## Verification loop

```text
1. node scripts/aa-verify-project.mjs
2. Read tmp/aa-verify-project-report.json + docs/PR48_VERIFICATION_REPORT.md
3. Fix P0/P1 failures
4. Repeat until npm gates pass and Godot CLI passes (if installed)
5. Human completes editor signoff + evidence
```

---

## Distinction table (reports must use these)

| Label | Meaning |
|-------|---------|
| **automated verified** | npm validate + typecheck + test + build passed |
| **Godot CLI verified** | headless import + smoke_runner passed |
| **manual editor verified** | signed checklist in `docs/manual-playtests/` |
| **proxy functional** | ColorRect + proxy AnimationPlayer; not final art |
| **final-art blocked** | Requires authored assets pipeline |

No report may claim **full product completion** without **manual editor verified** + final art signoff.
