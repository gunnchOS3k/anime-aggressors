# Build Targets — Anime Aggressors

**Primary feel target:** Godot native desktop (editor + exported binary)  
**Secondary:** Godot web export embedded in `apps/web`  
**Not gameplay runtime:** TypeScript / Three.js battle

---

## Supported now

| Target | Command / path | Role |
|--------|----------------|------|
| **Godot editor playtest** | Open `game-godot/project.godot` → F5 | Primary development & QA |
| **Data validation** | `npm run validate:full-scope-production` | CI gate |
| **Data generation** | `node scripts/generate-godot-full-scope-data.mjs` | Regenerate fighter/move JSON |
| **TypeScript CI** | `npm run typecheck && npm test && npm run build` | Oracle + web shell |
| **Web shell (dev)** | `npm run dev` | Home, routing, legacy preview |
| **Godot web export** | `npm run godot:export:web` (when Godot CLI configured) | Secondary distribution |
| **GitHub Pages** | `npm run build:pages` | Wrapper + embedded Godot + docs |

---

## Local desktop export (Godot)

Requires Godot 4.2+ with export templates installed.

```bash
# Example — adjust preset name in Godot Export dialog
godot4 --path game-godot --export-release "macOS" build/AnimeAggressors.app
godot4 --path game-godot --export-release "Windows Desktop" build/AnimeAggressors.exe
```

**Status:** Export presets may need to be added in `game-godot/export_presets.cfg` — not blocking editor playtest.

---

## Web export policy

- Godot WASM build is **secondary** — acceptable latency tradeoff for browser demo
- `apps/web` embeds export at `#/godot` — must not reimplement combat in TS
- Embed may lag editor build until export pipeline runs in CI

---

## GitHub Pages wrapper

- Serves: home, docs links, Godot embed, legacy routes (labeled)
- Does **not** ship Three.js battle as primary CTA

---

## Future platforms (not supported now)

| Platform | Status |
|----------|--------|
| Android / iOS | Notes only — Godot mobile export possible post-F9 |
| Nintendo / PlayStation / Xbox | **Blocked** — no console support claimed |
| Steam | Future — requires F9 + store pipeline |

---

## Blocked / not claimed

- Console certification
- Cross-platform rollback netplay
- Using Unreal builds as the live product
- TS web canvas as authoritative combat

---

## Verification checklist

1. `game-godot/` opens in Godot 4 without import errors
2. F5 reaches Main Menu
3. `npm run validate:full-scope-production` passes
4. Web home shows Godot primary CTA + runtime banners
