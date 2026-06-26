# PC Playtest Guide

Two ways for friends on PC to try Anime Aggressors and send feedback. Web is fastest; Windows ZIP is for controller and local performance testing once packaged.

## Route A — easiest web test (recommended)

1. Open https://gunnchOS3k.github.io/anime-aggressors/
2. Click **Play Match**
3. Use keyboard or plug in Xbox / PlayStation / PC controller
4. Try **Impact Dummy Derby** from the home screen
5. Fill out the [feedback form](feedback-form.md)

**Tips**

- Chrome or Edge recommended; Firefox usually works.
- Two keyboards work for couch play (P1 arrows, P2 WASD).
- If the page is blank, hard-refresh (Ctrl+Shift+R) and check the URL includes `#/` routes.

## Route B — downloadable Windows build

**Status: SHIP BLOCKED** — desktop packaging is not wired yet.

Planned build command (from repo root):

```bash
npm run build:desktop:win
```

Expected artifact:

```text
releases/windows/AnimeAggressors-Playtest-v0.2.0.zip
```

When available:

1. Download the ZIP from GitHub Releases (or itch.io restricted page).
2. Extract and run `AnimeAggressors.exe`.
3. Allow Windows SmartScreen if prompted (unsigned playtest build).
4. Test with a controller; compare feel to the web build.
5. Submit [feedback](feedback-form.md) noting **Windows ZIP** as your route.

## itch.io restricted testing (planned)

Stage 3 of [PC distribution](../PC_DISTRIBUTION_PLAN.md): unlisted itch.io page with password or download keys for friends. Not live yet.

## Before you play

- [Tester checklist](tester-checklist.md)
- [Known issues](known-issues.md)
