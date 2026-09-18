# Dimension matrix

| Dimension | Status | Evidence | Blocker |
|---|---|---|---|
| build | PASS | Godot --import |  |
| launch | PASS | godot --import + smoke_runner (canonical) |  |
| save_load | PARTIAL | test:game-core / persistence tests | HUMAN_VALIDATION_REQUIRED |
| menus | PASS | res://tests/smoke_runner.gd |  |
| input | PARTIAL | regression scripts exist; host smoke limited | HUMAN_VALIDATION_REQUIRED |
| pause_resume | PARTIAL | wave020 pause diagnostics exist historically; smoke coverage | HUMAN_VALIDATION_REQUIRED |
| crash_recovery | PARTIAL | mini_soak 5x headless quit | HUMAN_VALIDATION_REQUIRED |
| persistence | PARTIAL | test:game-core / persistence tests | HUMAN_VALIDATION_REQUIRED |
| frame_pacing | BLOCKED | device/frame telemetry needs interactive or device run | PHYSICAL_HARDWARE_REQUIRED |
| leaks | BLOCKED | leak instrumentation needs longer soak + profiler | PHYSICAL_HARDWARE_REQUIRED |
| loading | PASS | godot --import |  |
| asset_validation | PASS | npm run validate:character-assets |  |
| resolution | PARTIAL | viewport/export presets present | HUMAN_VALIDATION_REQUIRED |
| audio | PASS | npm run validate:anime-digital-art-audio-closure |  |
| a11y | HUMAN_VALIDATION_REQUIRED | automation incomplete for disabled-user validation | HUMAN_VALIDATION_REQUIRED |
| local_multiplayer | PARTIAL | local versus paths exist; need bot/host soak | HUMAN_VALIDATION_REQUIRED |
| networking | PASS | npm run test:netplay + test:rollback |  |
| offline | PASS | Godot local offline primary runtime |  |
| install_update | PARTIAL | digital-rc-update-rollback.mjs exists | HUMAN_VALIDATION_REQUIRED |
| android | BLOCKED | no adb device | PHYSICAL_HARDWARE_REQUIRED |
