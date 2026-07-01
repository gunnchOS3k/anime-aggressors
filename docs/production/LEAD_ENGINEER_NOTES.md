# Lead Engineer Notes

## Owns

- Runtime architecture (TypeScript shell / Godot gameplay / Unreal R&D split)
- Engine integration and input system
- State machines and choreography runtime
- Build, deploy, GitHub Pages, Godot web export
- Performance budgets
- Rollback/netplay future
- Debug tools and validators

## Deliverables

- `FighterAssetLoader`, `MoveTimeline`, CI validators
- Green `npm run quality` and `build:pages`
- Clear failure messages when content gates fail

## Non-negotiables

- DEBUG FALLBACK must never pass as production silently
- Manifest + cache contract for `#/godot`
