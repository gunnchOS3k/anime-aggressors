# Known Playtest Issues

Honest list for friends — not a bug backlog. Updated when we ship a new playtest.

## Web build

- Placeholder character/stage visuals (no final GLB assets yet)
- No public online multiplayer — local / same-keyboard / same-machine only
- Audio is placeholder WebAudio SFX, not final mix
- Some UI is dev-facing (Rollback Debug, Prototype Lab)

## Controllers

- Most standard USB gamepads work via the browser Gamepad API
- Bluetooth gamepads vary by browser/OS; wired is more reliable for playtests
- Edge-IO wearable hardware is simulator-only unless you have a dev board

## Windows ZIP (not shipped yet)

- `npm run build:desktop:win` does not exist yet
- Target: `releases/windows/AnimeAggressors-Playtest-v0.2.0.zip`
- See [PC Playtest Guide](PC_PLAYTEST_GUIDE.md) Route B

## Reporting new issues

Use the [feedback form](feedback-form.md) with steps to reproduce and browser/controller info.
