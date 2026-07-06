# iOS / TestFlight Testing

## Free Apple Account (Own Devices)

A free Apple ID lets you deploy to **your own** iPhone/iPad through Xcode:

1. Export iOS project from Godot (**Project → Export → iOS**).
2. Open the generated Xcode project.
3. Sign in with your Apple ID under **Signing & Capabilities**.
4. Connect your device and run from Xcode.

This path is ideal for solo device verification. It does **not** require the paid Apple Developer Program.

## TestFlight (Friend Testing)

External friend testing on iOS requires the **Apple Developer Program** ($99/year):

1. Export iOS project from Godot 4 (`game-godot/`).
2. Open in Xcode on macOS.
3. Configure signing with your Developer team.
4. Archive and upload to App Store Connect.
5. Create a **TestFlight** internal or external testing group.
6. Invite testers by email; they install via the TestFlight app.

## Godot iOS Export Notes

- Godot exports an **Xcode project**, not a standalone `.ipa` from the editor alone.
- Use **GL Compatibility** renderer (already set in `game-godot/project.godot`).
- Touch controls auto-enable on iOS via `TouchInputManager`.
- Production gameplay remains in `game-godot/` — do not migrate combat to a separate runtime.

## Recommended Path for Early Mobile Friends

| Platform | Easiest path |
|----------|----------------|
| iPhone testers (no paid account) | **itch.io HTML** or **GitHub Pages** web build |
| iPhone testers (paid account ready) | TestFlight |
| Android testers | Debug APK sideload |

## Web Alternative (No Apple Setup)

For iOS friends without TestFlight, share the itch.io or GitHub Pages Godot web build. Mobile Safari supports the touch overlay when **Mobile friendly** is enabled on itch.io.

See `ITCH_IO_MOBILE_UPLOAD.md`.
