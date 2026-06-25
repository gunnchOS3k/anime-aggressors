# ADR-0002: Desktop Shell — Electron vs Tauri

**Status:** Accepted (provisional — revisit at E1 scaffold)  
**Date:** 2026-06-24  
**Deciders:** Engineering / product  
**Context:** Track E — desktop distribution for Windows, macOS, Linux

---

## Context and problem statement

Anime Aggressors ships first as a **web app** (`apps/web`). Desktop distribution should wrap the same production build for couch play, offline demos, and eventual store packaging — without maintaining a second game renderer.

The team needs a shell decision before E1 scaffold work. Constraints:

- Small team; TypeScript-heavy; limited native UI bandwidth.
- Game rendering already works in Canvas + Web Gamepad API.
- Binary size and update story matter for indie distribution.
- CI must stay green — desktop is **not** in required `quality` gate until E1.

---

## Options considered

### Option A — Electron

**Description:** Chromium + Node embedded; load `apps/web/dist` in `BrowserWindow`.

| Pros | Cons |
|------|------|
| Mature ecosystem; extensive docs | Large download (~150 MB+) |
| Web Gamepad API identical to browser | Higher memory footprint |
| Easy devtools for debug | Security surface (Node in renderer if misconfigured) |
| Auto-update via `electron-updater` well documented | Slower cold start |

### Option B — Tauri 2.x

**Description:** System WebView + Rust host; embed static `apps/web/dist`.

| Pros | Cons |
|------|------|
| Small binary (~5–15 MB class) | WebView differences per OS (WKWebView, WebView2, WebKitGTK) |
| Rust backend for future native hooks | Rust toolchain for contributors |
| Strong security defaults (no Node in webview) | Gamepad API testing needed per platform |
| Fits "web build as renderer" model | Younger ecosystem than Electron |

### Option C — Native C++ shell (SDL/GLFW + native engine)

**Description:** Desktop app using Track C native renderer.

| Pros | Cons |
|------|------|
| Best performance potential | Duplicates web renderer effort |
| No WebView quirks | Largest engineering cost |
| | Blocks desktop on C++ graphics — not ready |

**Rejected for E0–E2.** Revisit only if WASM/native sim + custom renderer becomes authoritative (unlikely near-term).

---

## Decision

**Recommend Option B — Tauri 2.x** for the desktop shell, wrapping `apps/web` production build.

**Electron remains the documented fallback** if Tauri blockers emerge (WebView gamepad gaps on a target OS, signing pipeline issues, or team Rust capacity).

### Rationale

1. **Same renderer:** `apps/web` Vite build is the single UI/sim path — aligns with architecture principle "one sim path."
2. **Size:** Smaller artifacts improve shareability for playtests and jam submissions.
3. **Security:** No Node in renderer reduces attack surface for a game that may add online lobbies later.
4. **Track C optional:** Tauri Rust side can later call `native/engine` without replacing the web canvas immediately.
5. **CI boundary:** Desktop scaffold stays optional until E1; neither Electron nor Tauri in required `npm run quality` today.

---

## Implementation consequences (Tauri path)

1. Create `apps/desktop/` Tauri project when E1 starts — minimal `tauri.conf.json` pointing `distDir` to `../web/dist`.
2. Build order: `npm run build -w anime-aggressors-web` → `cargo tauri build`.
3. Validate **Web Gamepad API** on Windows (WebView2), macOS (WKWebView), Linux (WebKitGTK) — document gaps in E3.
4. Offline: serve `dist/` via `tauri://` or embedded asset protocol; no network required for couch play.
5. Do not add desktop to required CI until E1 produces a reproducible local build.

### Electron fallback triggers

Migrate to Electron if **any** of:

| Trigger | Threshold |
|---------|-----------|
| Gamepad API | Broken or inconsistent on 2+ target OSes in Tauri WebView |
| WebGL/Canvas | Performance regression > 20% vs Chrome |
| Signing/notarization | Tauri pipeline blocked > 2 weeks |
| Team capacity | No Rust maintainer and Electron spike ships faster |

---

## Rejected for now

| Option | Reason |
|--------|--------|
| Native C++ game window | No native renderer; Track C is sim-only |
| PWA-only "desktop" | Insufficient for store distribution and offline artifact (E4) |

---

## Milestones (Track E)

| ID | Action |
|----|--------|
| E0 | This ADR |
| E1 | Tauri scaffold (or Electron if fallback triggered) |
| E2 | Embed `apps/web/dist` |
| E3 | Controller validation matrix |
| E4 | Offline installable artifact |
| E5 | Code signing + updater research |
| E6 | Release packaging |

---

## References

- `apps/desktop/PRODUCT_SCOPE.md`
- `docs/ROADMAP_FULL_COMPLETION.md` — Track E
- [Tauri 2 documentation](https://v2.tauri.app/)
- [Electron documentation](https://www.electronjs.org/docs/latest/)

---

## Review schedule

- **E1 scaffold complete:** Confirm WebView gamepad on all target OSes.
- **Before store submission:** Re-evaluate Electron if signing or update pain exceeds threshold.
