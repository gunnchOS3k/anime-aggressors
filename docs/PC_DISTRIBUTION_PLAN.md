# PC Distribution Plan

Staged path for friend playtests on PC. Console stores are not the right immediate playtest channel.

## Stages

| Stage | Channel | Status | Best for |
|-------|---------|--------|----------|
| **1** | GitHub Pages web playtest | **LIVE** | Fastest friend feedback, zero install |
| **2** | GitHub Releases Windows ZIP | SHIP BLOCKED | Controller feel, local performance, offline |
| **3** | itch.io restricted / unlisted page | Planned | Friendlier game page, per-platform uploads, password/keys |
| **4** | Steam Playtest | Later | Larger audience, Steam overlay, more setup |
| **5** | Console exploration | Much later | Certification, dev kits, not for early feedback |

## Stage 1 — Web (now)

- URL: https://gunnchOS3k.github.io/anime-aggressors/
- Deploy: `main` → GitHub Pages workflow
- Guide: [PC Playtest Guide — Route A](playtest/PC_PLAYTEST_GUIDE.md)

**Why first:** One link, no SmartScreen, works on any PC with a modern browser.

## Stage 2 — Windows ZIP

Planned command:

```bash
npm run build:desktop:win
```

Target artifact:

```text
releases/windows/AnimeAggressors-Playtest-v0.2.0.zip
```

**Why second:** Better for full-screen, consistent gamepad polling, and friends who dislike browser tabs.

**Blockers:** Desktop shell scaffold exists but packaging script and signed/unsigned release flow are not implemented.

## Stage 3 — itch.io restricted

- Create unlisted project page with screenshots/GIF from `docs/media/`
- Upload web + Windows builds per platform
- Restrict with password, download keys, or invite-only
- Link feedback form in page description

**Why third:** Feels like a real game page without public store pressure.

## Stage 4 — Steam Playtest

- Requires Steamworks app, depots, build review
- Stronger discovery and update channel than itch
- Defer until core combat and content pass a higher bar

## Stage 5 — Console

- Exploration only after PC playtest loop is stable
- Not suitable for “send friends a link this weekend”

## Feedback loop

All stages should point testers to:

- [Feedback form](playtest/feedback-form.md)
- [Tester checklist](playtest/tester-checklist.md)
- [Known issues](playtest/known-issues.md)
