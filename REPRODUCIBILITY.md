# Reproducibility — Anime Aggressors

This is a **product/game** repository. Commands below reproduce the digital game path. They are not a wireless experiment.

Human fun/usability remains `HUMAN_QA_PENDING`. Pixel 6a install/launch is a separate `artifacts/pixel6a/` session.

## Canonical commands

```bash
npm install
npm test
npm run godot:check
npm run mobile:check
```

Play in Godot 4.5 (production runtime is `game-godot/`):

```bash
# Import game-godot/project.godot in Godot 4.5, then F5
```

Android debug export (Godot 4.5 + Android SDK + JDK 17):

```bash
export GODOT_BIN="$HOME/Applications/Godot/Godot-4.5.app/Contents/MacOS/Godot"
export JAVA_HOME="$HOME/Library/Java/JavaVirtualMachines/corretto-17.0.17/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
npm run godot:export:android
```

Package id: `com.gunnchos.animeaggressors`. See `docs/PIXEL_6A_ACCEPTANCE.md`.
