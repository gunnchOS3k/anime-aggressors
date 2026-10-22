# Private-match replay persistence

Base `7c25c2996f8adcee97ec2187a14bfc578d8681bf`. Official V1 and RC2 remain NOT READY.

`ReplayStore.write_json` stores `JSON.stringify` of the record `create_record` already builds: `replay_version`, `build`, `meta`, `frames` (`frame`, `p0`, `p1`, `checksum`), `frame_count`, and `integrity`. Nothing in the product called it. `PrivateNetplayStack.simulate_match_frames` created that record, ran `verify_record` and `replay_checksum_chain`, and returned those in-memory results. There was no reader. `user://private_netplay_digital_pass.json` is the digital-pass evidence snapshot, not this record. Crash-census `.jsonl` and the web replay modules are different formats and were not used.

`simulate_match_frames` now calls `write_json` on `ReplayStore.DEFAULT_PATH` (`user://aa_private_match_replay.json`). `read_json` loads that same JSON, restores integer fields JSON parsing turns into floats, and checks the existing `verify_record` integrity hash plus `replay_checksum_chain`. A changed `integrity` string fails with `integrity_fail`. No replay browser, playback, or second format.

Isolated probe, no asset import, user dir `aa-replay-persist-probe` (not `Anime Aggressors`):

```sh
./tools/replay_persist/run_isolated_probe.sh
```

Before, exit 1:

```
HAS_WRITE_JSON true
HAS_READ_JSON false
MATCH_OK true
MEMORY_VERIFY true
MEMORY_FRAMES 12
REPLAY_WRITTEN false
DISK_EXISTS false
ROUNDTRIP false
FAIL completion kept the verified record in memory and did not leave user://aa_private_match_replay.json
```

After, exit 0:

```
HAS_READ_JSON true
REPLAY_WRITTEN true
DISK_EXISTS true
DISK_BYTES 6016
RELOADED ok=true frame_count=12 seed=77 roster=["ember-vale", "rook-ironside"] integrity=619531140
RELOADED_VERIFY { "ok": true, "errors": [], "frame_count": 12 }
RELOADED_CHAIN { "ok": true, "checked": 12, "mismatches": 0 }
TAMPER_REJECTED true
ROUNDTRIP true
PASS private match replay roundtrip
```

The probe file is `aa-replay-persist-probe/aa_private_match_replay.json`. Owner `aa_save.cfg` stayed mtime 1790883337 size 626. Owner `aa_rulesets.cfg` stayed mtime 1789773945 size 99. Owner `aa_private_match_replay.json` and `private_netplay_digital_pass.json` stayed absent. `df` stayed 15 GiB available. No `.godot` import cache. Full Godot project import was not run. GameState save rules were not changed.
