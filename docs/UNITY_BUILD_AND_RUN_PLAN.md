# Unity Build and Run Plan — Local Desktop

Second proof step, **after** the Editor test plan passes
(`UNITY_EDITOR_TEST_PLAN.md`) and **before** any WebGL work
(`UNITY_WEBGL_LATER_PLAN.md`). GitHub Pages is last.

**Status: not attempted yet. Nothing here is claimed as done.**

---

## Build settings

Scenes are registered in `ProjectSettings/EditorBuildSettings.asset` in
launch order: Boot, Title, MainMenu, ModeSelect, CharacterSelect,
StageSelect, Loading, Battle, Training, Results, CombatProof (dev). BootScene
is index 0, so a build launches like a real game.

## macOS build (first target)

1. Pass the Editor test plan first.
2. File → Build Profiles (or Build Settings) → platform: macOS.
3. Verify the scene list matches the order above.
4. Build to `builds/macos/` (folder is untracked; never commit builds).
5. Launch the .app and re-run the Editor test plan end to end.
6. Record a video of the desktop run — same proof rules as Play Mode.

Headless alternative once a build method script exists (later):

```bash
"/Applications/Unity/Hub/Editor/6000.0.23f1/Unity.app/Contents/MacOS/Unity" \
  -batchmode -quit -projectPath unity/AnimeAggressorsUnity \
  -buildTarget StandaloneOSX -logFile -
```

(Requires a C# BuildPipeline entry point; do not add until the Editor gate
passes.)

## Acceptance for this step

- Desktop app launches into Boot → Title without the editor.
- Full versus and training loops work in the built app.
- No console errors in `Player.log`.
- Video recorded.

Only after this passes does WebGL become relevant.
