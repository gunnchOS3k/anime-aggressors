# Unity WebGL Plan — LATER

WebGL is the **third** proof step. It is intentionally not started.

Order of proof (fixed):

1. Unity **Editor** Play Mode — `UNITY_EDITOR_TEST_PLAN.md` — first
2. Local **desktop** build — `UNITY_BUILD_AND_RUN_PLAN.md` — second
3. **WebGL** local build — this doc — third
4. **GitHub Pages** deploy — last, and only after 1–3 are proven with video

**Status: not started. No WebGL build exists. No Pages deploy exists.
Do not claim otherwise anywhere in this repo.**

---

## When steps 1 and 2 have passed

- Install the WebGL Build Support module for 6000.0.23f1 via Unity Hub.
- Build WebGL locally and serve from a local static server (not Pages).
- Re-run the Editor test plan in the browser; expect and document
  differences (input focus, performance, audio autoplay policies).
- Known risks to evaluate then: legacy `OnGUI` debug HUD performance in
  WebGL, `Input.anyKeyDown` browser focus behavior, `Time.timeScale`
  pause behavior in background tabs.

## Only after local WebGL is proven

GitHub Pages deployment gets its own plan and validation. The existing
Godot-era Pages pipeline must not be reused to present a Unity build; the
web shell remains TypeScript support tooling.
