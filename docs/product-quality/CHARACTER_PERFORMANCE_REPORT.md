# Character Performance Report

Device target: Google Pixel 6a (`27211JEGR06194`). Quality tiers: Low / Medium / High.

## Budget rules

Reduce particles → dynamic lights → secondary motion → shadows → post before cutting identity.

## Anime Aggressors

| Metric | Low | Medium | High | Notes |
| --- | --- | --- | --- | --- |
| Fighter viewport res | 160×200 | 220×280 | 280×360 | SubViewport per fighter |
| MSAA | Off | 2× | 2× | Already 2× default |
| Aura overlays | Level shapes only | + pulse alpha | + extra particles later | Shape language not recolor-only |
| Facial | Expression chip off | Chip + glyph | Chip + glyph | Mobile-readable |
| Secondary motion | Playback speed only | + throw tweens | + bone secondary (future) | |
| Expected avg FPS | ≥50 | ≥45 | ≥40 | Pending Pixel profile this branch |
| Heavy-effect min FPS | ≥30 | ≥28 | ≥25 | Aura burst + KO camera |

**Status:** Personality layer is CPU-cheap (speed_scale, ColorRect aura shapes, Label glyphs). Full Pixel capture pending rebuild on this branch.

## Pedestrian Pursuit

| Metric | Low | Medium | High | Notes |
| --- | --- | --- | --- | --- |
| Runner mesh | Box figure | Box + accent | Box + hair/FX | Procedural silhouettes |
| Name labels | Off | On | On | Label3D billboard |
| Secondary | Off | Hair sway | Accent spin (kinetic) | No cloth sim |
| Particles | Drift only | Drift + boost cue | Drift + boost | |
| Expected avg FPS | ≥55 | ≥50 | ≥45 | |

**Status:** Procedural bodies avoid skinning cost; four racers is intentional budget.

## Actions before shipping High as default on Pixel

1. Capture avg/min FPS during anime aura burst duel and pedestrian cup start boost piles.
2. If min FPS < 28 Medium, force Low aura shapes and disable Label3D at distance.
3. Record numbers into review packages.
