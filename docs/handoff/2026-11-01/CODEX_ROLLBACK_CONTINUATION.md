# Anime input-history correction — November 1, 2026

Source recovered from `b4f9808b4e52b8a6b80fdb1cc286d56ec3f94c91` on `integration/v1-preserved-candidate-20261025`. Existing untracked outputs and all other worktrees remain preserved. This is a Codex-authored engineering candidate awaiting a distinct review, with no human or release approval.

`RollbackSessionGd.confirm_remote_input` previously replayed a fixed rollback window instead of stopping at the played tip. Correcting frame zero after one played frame therefore created seven unplayed checksum frames. Rebuilding inputs from maps also missed an implicitly predicted default and retained stale input maps indefinitely.

The correction now replays exactly the retained rows through the original tip, preserves unrelated slot input, marks matching predictions confirmed, rejects contradictory confirmed packets and malformed/unbounded packets before map changes, and prunes input maps with the retained history. Current and bounded future inputs can still queue before their actual frame. Inputs/checksums remain a private scaffold: no game-world snapshot restoration or shipping rollback is enabled.

Actual Godot `4.7.1.stable.official.a13da4feb` executed a minimal standalone fixture containing the exact production session/latency scripts and the new regression. The baseline fails 17 of 20 assertions with exit 1; the candidate passes all 20 with exit 0 and no engine errors. The same regression is added to the existing hosted physics suite. Python AST and `git diff --check` pass. Full game imports, builds, exports, renderer captures and device runs were held because internal free space remains about 13 GiB, below the 18 GiB production floor.

Initial harness parsing and sandbox engine-initialization failures are retained under `outputs/rollback_input_history_20261101`. A minimal engine invocation subsequently received automatic approval to initialize the dedicated `CodexRollbackInputCheck-20261101` test profile; no installed binary was changed or copied. An attempted workspace hardlink was denied and created no link. Final fixture files totaled 83,898 bytes at measurement. Exact sources, raw log hashes, remaining limits and false gate flags are in `ROLLBACK_INPUT_HISTORY_ENGINE.json` beside this file.

Next: obtain distinct source/test review of this bounded change; separately test rejection propagation in `private_netplay_stack.gd` (its existing caller ignores confirmation errors), without editing a Cursor-owned active checkout. When storage permits, run the hosted/full physics suite on the new exact SHA, then resume the existing isolated flat-world body/jump replay and its remaining grabs, projectiles, forms, edges and terminal-state work. Do not describe input checksum replay as combat rollback. The current directive's ten fighters, Rosamere manifestations and six Trials supersede stale nine-fighter historical text; no roster/story content changed here.

`HUMAN=false`, `RC2=false`, `V1=false`.
