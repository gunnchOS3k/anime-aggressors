# Animectl

Repo-native control plane for Anime Aggressors PR #118 V1.4.

## Install

No global install. From repo root:

```bash
chmod +x ./animectl   # once
./animectl doctor
```

Requires Python 3 + existing repo Node tooling.

## Quick loop

```bash
./animectl doctor
./animectl audit
./animectl verify models
./animectl inspect runtime --fighter ember-vale --body female --json
./animectl acceptance --exact-head --quick
```

## Full acceptance

```bash
./animectl acceptance --exact-head --full
```

Local heavy evidence lands in `.acceptance/<git-sha>/` (gitignored).
Canonical pointer: `artifacts/acceptance/ANIME_ACCEPTANCE_LATEST.json`.

## Browser automation

Playwright specs live under `tests/e2e/`. Prefer:

```text
Cursor → ./animectl → Playwright CLI
```

Do not use Playwright MCP as the primary acceptance path.
If browsers cannot install (disk), digital CI reports `BLOCKED_EXTERNAL` / `PASS_WITH_NOTES` — not a false green.

## Android

```bash
./animectl android doctor
./animectl android build --exact-head
./animectl android smoke   # REQUIRES_PHYSICAL when no device
```

## Blender

```bash
./animectl art doctor
./animectl art validate
```

Canonical production remains headless Blender + `tools/blender`. Blender MCP is optional, never required for CI.

## Evidence locations

| Kind | Path |
|------|------|
| Local acceptance | `.acceptance/<sha>/` |
| Latest pointer | `artifacts/acceptance/ANIME_ACCEPTANCE_LATEST.json` |
| Model manifest | `data/bibles/battle_model_manifest_v1_4.json` |
| Packaged web GLBs | `apps/web/public/assets/characters/` |

## Human gates

Automation must never flip:

- `G6_VISUAL_READABILITY`
- `G8_HUMAN_FEEL`
- `G9_FINAL_ART_APPROVED`
- `MERGE_AUTHORIZED`

See [ANIMECTL_COMMAND_REFERENCE.md](./ANIMECTL_COMMAND_REFERENCE.md).
