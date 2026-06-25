# Desktop App — Product Scope

**Status:** Planning — not in required CI quality gate.

## Shell decision

See `docs/decisions/ADR-0002-desktop-shell.md`.

**Interim recommendation:** Tauri 2.x wrapping `apps/web` production build for smaller binary size; Electron remains fallback if Tauri blockers emerge.

## Technical path

1. `apps/web` `npm run build` → static assets
2. Desktop shell loads local `file://` or embedded server
3. Gamepad APIs via Web Gamepad API (same as web)
4. Offline artifact per platform (Windows/macOS/Linux)

## CI policy

- No desktop build in required CI until E0/E1 complete
- Document-only until shell scaffold lands

## Milestones

See `docs/ROADMAP_FULL_COMPLETION.md` Track E.
