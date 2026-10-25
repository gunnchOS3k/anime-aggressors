# Safe development storage recovery — October 12, 2026

Active Data volume `/dev/disk3s5`, APFS container `disk3`: about 460 GiB total. Initial inventory observed 3.4 GiB free; cleanup preflight observed 3.761 GiB. Earlier 0.4–2.3 GiB values were historical. Space fluctuates independently with active applications and system VM (about 15 GB at the APFS snapshot); no snapshot or system-managed data was modified.

## Inventory and protected data

Downloads: about 82.18 GiB allocated by `du`; primary workspace 52.89 GiB, repos 52.59 GiB, owner backups 307.5 MiB. Largest repository directories: main Anime checkout 9.31 GiB; active closure checkout 6.86 GiB; device OS 2.67 GiB; pedestrian pursuit 2.40 GiB; passport and taste worktrees approximately 2.37/2.26 GiB. These are protected source/history/artifacts or unrelated projects. The active checkout includes 5.22 GiB artifacts, 664 MiB Godot project, 569 MiB art sources and 235 MiB existing build output. No directory was classified disposable solely because it is ignored/untracked.

Library Caches: 2.76 GiB, including active Chrome 1.42 GiB, Playwright 478 MiB installed browsers, Codex 269 MiB active runtime, node-gyp 63.8 MiB, Homebrew 50.2 MiB and Godot 6.01 MiB. `.cache` totals 1.63 GiB, including 1.52 GiB required bundled runtimes; npm about 994 MiB. Dependency and browser caches remain to preserve offline builds and active unrelated work. Docker CLI/application is absent; a docker networking helper is active. No Docker pruning was run.

`/private/tmp` 1.49 MiB; task TMPDIR about 53.9 MiB. Isolated review wrappers are mostly 20 KiB symlink/config shells; some paths remain referenced by immutable launch evidence. They were preserved. All 33 Git worktrees were inventoried, with HEAD, branch, uncommitted status and import-cache size. Imported caches in inactive checkouts total only about 22 MiB and were left intact: deleting/rebuilding them provides little durable benefit. Source-side `.import`, original audio/models/Blender, `.git`, owner backups, saves, fixtures, credentials and evidence remain protected.

Targeted >500 MiB scan of workspace/caches/temp found two main Anime Git packs (726.2/559.7 MiB), both RED. Inaccessible directories were logged without broadening read privileges. This was a targeted inventory, not a full-disk crawl. Allocated `st_blocks`/`du` sizes cannot establish unique APFS clone/snapshot storage; actual `df`/free-space delta is recorded separately.

## Exact path actions and proposals

| Exact path | Allocated size | Risk/class | Backup or recreation | Action |
|---|---|---|---|---|
| /Users/gunnchos/Library/Caches/Godot/editor_doc_cache-4.5.res | 2.89 MiB | GREEN; documentation only | Built into installed engine | Removed; rebuilt on editor start |
| /Users/gunnchos/Library/Caches/Godot/editor_doc_cache-4.7.res | 3.12 MiB | GREEN; documentation only | Built into installed engine | Removed; rebuilt on editor start |
| /Users/gunnchos/Library/Caches/Google/Chrome/Profile 3/Cache | 771.6 MiB | YELLOW; active browser | Network cache; offline content may be affected | Preserve; close browser and obtain path-specific approval first |
| /Users/gunnchos/Library/Caches/Google/Chrome/Profile 3/Code Cache | 194.5 MiB | YELLOW; active browser | Compiled website code | Preserve while Chrome is active |
| /Users/gunnchos/Library/Caches/Google/Chrome/Profile 6/Cache | 312.4 MiB | YELLOW; active browser | Network cache; offline content may be affected | Preserve; owner approval first |
| /Users/gunnchos/Library/Caches/Google/Chrome/Profile 6/Code Cache | 180.3 MiB | YELLOW; active browser | Compiled website code | Preserve while Chrome is active |
| /Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/local_media/kaia_authentic_stock_loss.avi | 133.0 MiB | YELLOW; native original/failure | No independent backup verified | Preserve; external archive with owner approval only |
| /Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/local_media/roster_landings_1012.avi | 234.9 MiB | YELLOW; native original/failure | No independent backup verified | Preserve; external archive with owner approval only |
| /Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/local_media/roster_motion_refinement_b5f2.avi | 181.2 MiB | YELLOW; native original/failure | No independent backup verified | Preserve; external archive with owner approval only |
| /Users/gunnchos/Downloads/gunnchos-7gc-research-product-spine/repos/_anime_v1_closure/artifacts/v1_closure/spectral_feedback/local_media/roster_transitions_1012.avi | 220.0 MiB | YELLOW; native original/failure | No independent backup verified | Preserve; external archive with owner approval only |

Each of the two removed documentation caches was canonicalized, SHA256/allocated size recorded, checked with `lsof` for no open consumer, checked for project/evidence references and revalidated immediately before unlink. Producer/recreation: Godot editor creates its documentation cache from installed engine class data. Source configuration and imported resources were untouched. No original AVI was removed, even when an MP4 exists. `2.638` GiB of native originals across 32 files remain; valid stream metadata/source bindings are in NATIVE_MEDIA_INVENTORY.json. Unknown lineage is marked unknown. No independent off-volume/remote backup is verified; no external drive is mounted. Older valuable evidence should be archived and checksum-verified off-volume before any exact owner removal decision.

## Measured recovery and integrity

Removed allocated files: 6.016 MiB. Immediate measured free-space net delta: 5.414 MiB; individual observations are in CLEANUP_LEDGER.json. This is far below the 5–10 GiB target. No same-volume move was counted as recovery, and unrelated free-space growth is not attributed to cleanup. Latest capacity while writing this report: 3.582 GiB.

All 33 worktree paths/heads/branches match the before/after inventory. Cleanup left active HEAD `a1b8deb605fcbd655c2dd0d4d6c214f5da8bbf18` and branch unchanged; existing uncommitted probe evidence was preserved. AuraFractionalBoundary smoke test PASS (153 boundary cases, 216 moves, 21,816 integer dictionaries); no full integration rerun. Evidence hashes/path reconciliation follows this checkpoint. Source/import configs were never removed, so offline Godot loads use their existing imports. Regenerable documentation cache is the only cleanup.

## Recording safety and next action

Native 60 fps capture can resume only if a new atomic preflight accepts: 2 GiB protected reserve + 256 KiB per capped frame + 100 MiB for conversion/sheets. A 3,400-frame pilot requires about 2.928 GiB free. Current capacity can satisfy this preflight, but is volatile. The new guard monitors free capacity every half-second, interrupts only its own child before the reserve is crossed, preserves every partial AVI/log, prevents duplicate Godot/FFmpeg jobs, refuses existing labels, and records PREPARED/RUNNING/failed/completed-unverified/verified states. Three independent guard tests pass, including simulated low-space interruption with original partial file preservation. No media fidelity/resolution/audio/frame-rate was reduced. Native MovieWriter 60 fps is not a sustained device-FPS measurement.

Heavy exports remain blocked below 18 GiB. No platform export or cache-wide prune ran. No native original, screenshot, failure, source, dependency installation or worktree was deleted. There is no safe verified 5–10 GiB cleanup opportunity in this audited scope. Further recovery requires an owner-selected off-volume archive or explicit browser-cache decision; neither is required to start a short capture while the existing reserve is satisfied.

## Subsequent guarded execution

Both bounded all18 native energy jobs completed without crossing the reserve: energy_native_guard1012 (b3before) and energy_envelope_native1012 (c7after). Each produced2,747frames60fps45.783s, original native audio and2,566 verified frame/model samples. Before minimum monitoredfree3.424GiB; after minimum monitoredfree3.311GiB in its immutable RECORDING_STATE.json. Native originals are retained local-only; derived MP4/sheets are source-bound ownerdevelopment evidence. No automatic media deletion or lowered fidelity. These are energy/movement fixtures, not activeCPU/combo proof or sustainedhardwareFPS.

The initial32-original inventory is an immutable before snapshot; two new owned native masters were added after it. No prior original was replaced. Recovered9CPU traces and later neutral-cast/currentheavy counterplay probes are preserved source-bound. Current source uses sharedglobalVFXintensity toreduce shader density; the prior15suite gameplay/Story/save evidence remains preserved. All33historicalworktree paths/branches and owner backups remain intact.

Next storage action is a fresh guard preflight for any genuinely missing shortcapture. Do not repeat completed videos or remove native originals. Heavy18GiB exports remain blocked. Further multiGiB recovery needs path-specific owner-authorized off-volume archiving or a closed-browser cache decision; no such cleanup was executed. Allhuman/releasegates remainfalse.
