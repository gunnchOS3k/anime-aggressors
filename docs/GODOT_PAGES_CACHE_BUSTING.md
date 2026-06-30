# Godot Pages Cache Busting

## Why Command + Shift + R was required

GitHub Pages serves **static assets**. The Godot route uses **fixed filenames** between deploys:

- `/godot/index.html`
- `/godot/rescue-runtime.js`
- `/godot/runtime/<buildId>/index.html`
- `/godot/runtime/<buildId>/index.js`
- `/godot/runtime/<buildId>/index.wasm`
- `/godot/runtime/<buildId>/index.pck`

Browsers cache HTML, JavaScript, WASM, and PCK aggressively. When a new deploy reuses the same URL, users can keep an **old boot shell**, **old WASM**, or **old PCK** until a hard refresh forces revalidation. That is why the newest Godot scene only appeared after **Command + Shift + R**.

The fix is **cache busting**, not asking users to hard refresh.

## Build manifest

Each export writes `apps/web/public/godot/build-manifest.json`:

```json
{
  "buildId": "commit-sha-or-timestamp",
  "commit": "github-sha-if-available",
  "generatedAt": "iso timestamp",
  "runtimePath": "runtime/<buildId>/index.html",
  "rescueRuntimePath": "rescue-runtime.js"
}
```

`buildId` comes from `GITHUB_SHA` (first 12 chars), `git rev-parse --short HEAD`, or a timestamp fallback.

## Versioned URLs

- Boot shell iframes `runtime/<buildId>/index.html?v=<buildId>`
- Boot shell loads `rescue-runtime.js?v=<buildId>`
- Raw runtime `index.html` patches `index.js`, `index.wasm`, and `index.pck` with `?v=<buildId>`
- `#/godot` fetches `build-manifest.json` with `cache: "no-store"` and embeds `godot/index.html?v=<buildId>`

## Validation

```bash
npm run godot:export:web
npm run validate:godot-cache
GODOT_EXPORT_ROOT=apps/web/public/godot npm run assert:godot-export
```
