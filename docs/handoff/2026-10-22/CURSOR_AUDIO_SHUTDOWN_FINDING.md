# Cursor audio shutdown finding — October 22, 2026

No production audio code change. Official V1 and RC2 remain NOT READY. This note does not accept art, mix, balance, device, or release gates.

## Classification

Delayed AudioServer cleanup at process exit. Not an accumulating leak, not a static-cache leak, and not a measurement false positive. `stop()` releases `AudioStreamPlaybackWAV` on a later frame. `quit()` during scene-tree teardown does not provide that frame, so Godot's ObjectDB exit check still sees the playback and the `AudioStreamWAV` it references (reference count 1).

## Recorded handoff warning

Source test: `res://tests/v1_closure/FacialPerformance8D.gd`  
Evidence: `artifacts/v1_closure/production_8d/face_final_roster1022/full_output.log`  
Command record: `artifacts/v1_closure/production_8d/face_final_roster1022/verbose_command.json`  
Engine message format matches Godot 4.7 (`Reference count` and a counted ObjectDB warning). Godot 4.5 prints `WARNING: ObjectDB instances leaked at exit` without that count.

Verbatim tail:

```
WARNING: 10 ObjectDB instances were leaked at exit (run with `--verbose` for details).
   at: cleanup (core/object/object.cpp:2536)
Leaked instance: AudioStreamWAV:9223374052469508101 - Reference count: 1
Leaked instance: AudioStreamWAV:9223374059817929002 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223374216181582239 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223374223496448666 - Reference count: 1
Leaked instance: AudioStreamWAV:9223374055774620329 - Reference count: 1
Leaked instance: AudioStreamWAV:9223374044869430071 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223374044919761771 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223374219503471959 - Reference count: 1
Leaked instance: AudioStreamWAV:9223374044684881243 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223374044735212956 - Reference count: 1
```

That is 6 `AudioStreamWAV` and 4 `AudioStreamPlaybackWAV`. `CLEANUP_OBSERVATIONS.json` records the same split.

## Ownership

- `game-godot/scripts/audio/transformation_audio_8c.gd` creates two `AudioStreamPlayer` children in `setup()`. `fighter.gd` owns that node and calls `clear()` from `_exit_tree()`. `clear()` calls `voice.stop()` only. Synthesized streams live in the static `_cache` dictionary.
- `game-godot/scripts/audio/guard_audio_8c.gd` creates two `AudioStreamPlayer` children. `elemental_guard_8c.gd` parents that node on the fighter. `clear()` also only calls `voice.stop()`. Streams live in the static `_streams` dictionary.
- Players are freed with the fighter when the scene tree shuts down. Nothing removes the static dictionaries during play. That cache is bounded by fighter, stage, and event. It is not the exit leak.

## Reproduction

The full 72-configuration `FacialPerformance8D.gd` run was not repeated. Internal free space was 17 GiB before the probe, below the 18 GiB reserve, and that test imports roster GLBs. The probe below loads only the two production audio scripts and uses the same `stop()`-on-exit path. Logs: `artifacts/v1_closure/cursor_audio_shutdown/baseline/`.

Isolated project name `Cursor Audio Shutdown Probe` so owner saves are not written. Godot 4.7.1.stable.official.a13da4feb (`/opt/homebrew/bin/godot`, the handoff binary path) and Godot 4.5.stable.official.876b29033 (project feature pin).

```sh
godot --headless --verbose --path <isolated-probe-project> \
  --script res://tests/v1_closure/AudioShutdownProbe.gd -- --audio-mode=production_exit
```

Godot 4.7 `production_exit` (same-frame plays, then `quit()` with `clear()`/`stop()` inside `_exit_tree`) printed:

```
WARNING: 12 ObjectDB instances were leaked at exit (run with `--verbose` for details).
Leaked instance: AudioStreamWAV:9223372064201639382 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372064218416599 - Reference count: 1
Leaked instance: AudioStreamWAV:9223372064235193816 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372064251971033 - Reference count: 1
Leaked instance: AudioStreamWAV:9223372064268748250 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372064285525467 - Reference count: 1
Leaked instance: AudioStreamWAV:9223372064386188769 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372064402965986 - Reference count: 1
Leaked instance: AudioStreamWAV:9223372064419743203 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372064436520420 - Reference count: 1
Leaked instance: AudioStreamWAV:9223372064453297637 - Reference count: 1
Leaked instance: AudioStreamPlaybackWAV:9223372064470074854 - Reference count: 1
```

6 streams and 6 playbacks. The two extra playbacks versus the handoff's 4 are same-frame voice replacement; `framed_exit` still left orphaned playbacks after one physics frame. The handoff's 4 playbacks match two form voices plus two guard voices when cues are separated by real match frames. The object class is the same.

## What was ruled out

| Mode | Result on Godot 4.7 |
| --- | --- |
| `autoload_only` | No form/guard objects, no leak |
| `clear_caches` during `_exit_tree` | Cache size 0 and the same 12 leaks remain |
| `null_wait_keep_cache` | Stop, set `stream = null`, wait 8 frames, keep cache: 12 leaks remain |
| `stop_wait_keep_cache` | `stop()` only, wait 8 frames, cache still 3+3, voices 0: no ObjectDB warning |
| `await_release` | Stop, null stream, clear caches, wait 8 frames: no ObjectDB warning |

Godot 4.5 `stop_wait_keep_cache` also prints no leak. Static cache entries that are not held by an unreleased playback are not reported. Clearing the cache or assigning `stream = null` at teardown does not fix the warning, and nulling the stream on 4.7 can keep the leak after later frames. No production change was made.

## Packaged GLB

Not executed. Web and Android export presets use `export_filter="all_resources"` and `include_filter="*.json"`. That does not prove raw authored GLB bytes are inside a platform package. Free space stayed at 17 GiB, so no local export or import was started.

## Integration

Codex must not redo this diagnosis or "fix" it by clearing `_cache` / `_streams` or nulling `voice.stream`. Do not merge this branch into the art branch blindly; it adds a probe and this note only. Review the baseline logs before any later audio-lifecycle change.
