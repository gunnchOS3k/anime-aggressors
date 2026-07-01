# Anime Aggressors Arena (Unreal R&D)

## Create project (local)

1. Install UE 5.3+
2. New project → Games → Blank → **AnimeAggressorsArena**
3. Copy this folder structure into your Unreal project root or open from `game/unreal/AnimeAggressorsArena/`

If generating `.uproject` manually:

```json
{
  "FileVersion": 3,
  "EngineAssociation": "5.3",
  "Category": "Games",
  "Description": "Anime Aggressors high-fidelity R&D",
  "Modules": [
    {
      "Name": "AnimeAggressorsArena",
      "Type": "Runtime",
      "LoadingPhase": "Default"
    }
  ]
}
```

Save as `AnimeAggressorsArena.uproject` in this directory.

## Content plan

See `ContentPlan.md`.

## Export

- FBX fighters → `assets/exports/unreal/fighters/`
- Capture screenshots to `assets/refs/moodboards/unreal/`
