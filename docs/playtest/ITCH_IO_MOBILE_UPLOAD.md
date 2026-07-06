# itch.io Mobile Upload Guide

Use this guide to share the Godot web build with mobile testers via itch.io.

## Prerequisites

1. Run a fresh export locally:

```bash
npm run godot:export:web
npm run package:itch
```

2. Confirm the ZIP exists at `dist/anime-aggressors-itch-web.zip` and contains `index.html` at the root.

## Create or Edit Your itch.io Page

1. Sign in at [itch.io](https://itch.io) and open **Dashboard → Create new project** (or edit an existing playtest page).
2. Set **Kind of game** to **HTML**.
3. Upload `dist/anime-aggressors-itch-web.zip`.
4. Enable **This file will be played in the browser**.
5. Enable **Mobile friendly**.
6. Set **Viewport dimensions** to **1280 × 720** (or leave default if itch scales correctly).
7. Enable **Fullscreen button** so testers can launch fullscreen on phones.
8. Set visibility to **Restricted** or **Draft** while playtesting.
9. Share the private/unlisted page link with testers.

## Tester Instructions

- Open the itch page on mobile Safari or Chrome.
- Tap **Run game** → **Fullscreen** if available.
- Use on-screen touch controls (virtual stick + action buttons).
- If controls do not appear, open **Settings → Touch Controls → On**.

## Feedback

Collect notes using `docs/playtest/MOBILE_PLAYTEST_CHECKLIST.md` and file issues on GitHub.

## Notes

- This package is the **Godot `game-godot/`** runtime export, not the legacy Three.js web combat shell.
- Web hosting uses **GL Compatibility** and **single-threaded** export for broader mobile browser support.
