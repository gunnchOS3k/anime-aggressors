# anime-aggressors

Original fighter game for the gunnchOS3k family — **Godot 4** production gameplay runtime with a TypeScript/web shell for packaging and Labs.

> **Current release/state:** `INTEGRATED` game repo — **not** automatic Device Lab four-game *production* runtime proof.

Ecosystem portal: [gunnchos-research-portal](https://github.com/gunnchOS3k/gunnchos-research-portal) · Product charter: [gunnchOS3k_PRODUCT_CHARTER.md](https://github.com/gunnchOS3k/gunnchos-7gc-ai-ran-field-kit/blob/main/program/charter/gunnchOS3k_PRODUCT_CHARTER.md)

## What is this?

Anime Aggressors game sources: Godot battle runtime, web shell, validation oracle, assets.

## Why does it exist?

First-party playable creation that exercises handheld/DS-XL/Student game journeys without erasing education/work purpose.

## Where does it fit?

Product Charter **layer 9** (games). Consumed by Device Lab packaging paths when wired — repo presence ≠ Lab PASS.

## What is real today?

- Godot 4 project under `game-godot/`
- `npm run validate:full-scope-production` / generators
- Web shell for Pages/embed (may lag editor)

## What is simulated / modelled?

- Legacy web runtime under Labs — reference only
- Placeholder/stage assets where labeled

## What is physical / external pending?

- Device Lab production-runtime earn tokens (host/browser dependent)
- Physical device FPS/human certification tokens

## Try / inspect in 5 minutes

```bash
# Godot 4.2+: open game-godot/project.godot → F5
npm run validate:full-scope-production
```

## Architecture

See [docs/RUNTIME_SOURCE_OF_TRUTH.md](docs/RUNTIME_SOURCE_OF_TRUTH.md). Godot = gameplay SoT; web = shell; `packages/game-core` = oracle not shipping renderer.

## Repo map

| Path | Role |
|---|---|
| `game-godot/` | Production runtime |
| `apps/web` | Shell / Pages |
| `packages/game-core` | Spec oracle |
| `playtest-evidence/` | Playtest artifacts |
| `legacy/` | HISTORICAL paths |

## Interfaces

Packaging hooks toward `gunnchos-device-os` Device Lab; no claim that Lab tokens are green from this repo alone.

## Tests

```bash
npm run validate:full-scope-production
```

## Evidence

`playtest-evidence/` and CI validators. Lab scorecards live in device-os.

## Known gaps

Lab production runtime earn; content polish; device performance certification.

## Beginner path

Pick a fighter, pick an element, play — Godot is the real game.

## Intern path

Run validators; change one move JSON; regenerate; re-validate.

## Expert path

Keep runtime SoT clear; avoid claiming Unreal/web as shipping gameplay.

## Contribution path

Godot gameplay, validators, honest packaging. Label legacy web as non-final.

## Current release / state

**INTEGRATED** sources. Claim boundary: `game_repo_not_lab_runtime_proof`.

## Claim boundary

No commercial 6G · game repo ≠ Device Lab PASS · Cursor DRAFT-only.

---

## Retained detail (post–Cycle 3A front door)

Full prior README: [docs/history/README_PRE_WP012.md](docs/history/README_PRE_WP012.md).

### Quick start (retained)

```bash
npm run validate:full-scope-production
npm run generate:godot-full-scope
npm run dev   # web shell secondary
```
