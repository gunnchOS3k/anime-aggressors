# Current native integration checkpoint — 2026-10-25

Source `a9faeddf08f7b79aa5b16df374b599c32c77a622`, local branch `integration/v1-preserved-candidate-20261025`. Original draft123/133 remain unchanged. See NATIVE_VALIDATION_20261025.json and the TOP of ANI03_RESUME_STATE.md for current truth; earlier status below is preserved history.

Actual BattleScene/public-model capture succeeded with fixed observer. A separate independently reproduced CPU backward-attack defect is corrected and native counterplay now damages the player. Both body presentations of Ember/Juno are visible in35seconds of verified native MP4 output with game audio. NOT corrected private art, fullroster, KO/victory/rematch, sustained60fps or human acceptance. Failed old capture and source failures preserved. Owner saves unchanged.

Private-art dependent work still BLOCKED: repeated fresh USB reader faults despite mounted correct encrypted UUID. No private asset read/rehash/bake/export/injection performed. Current art-binding code is opt-in/source-only, not executed acceptance. Reuse existing sources/exports after transport and integrity guards pass. No public art or paid service.

Owner review: outputs/native_playable_review_20261025/OWNER_REVIEW.html; guarded manual launcher alongside, preflight-only passed. Exact next safe command: `python3 outputs/native_playable_review_20261025/play_manual.py --preflight-only`.

---

# Preserved integrated candidate — 2026-10-25

Branch: `integration/v1-preserved-candidate-20261025`. Base #133 `58689ce4754b82ec10b3b4ad461873204202b963`; original #123 `328160dfaebc7c9687b126ac85e5b08c75d78670`. Merge-base `3043da067afb155daf6a4c0eb42def41bdd2087c`.

All17 post-base art commits reviewed and forward-ported with `-x` and original authorship. Original43 worktrees preserved; candidate is a NEW44th, sparse to avoid a2GiB full materialization. Gameplay/Story/replay/PartyLink/UI contents equal #133; art tooling equal #123. The10 duplicate dirty files were NOT copied; the3older Story/network/replay dirty files remain untouched. Local refs plus3,017,550bytes of patches/nonprivate text snapshots under `outputs/anime-aggressors/ownership-reconciliation-20261025` preserve pre-integration work. Ignored/private originals remain in place, not falsely covered by commits.

Other Cursor branch patches were compared. Older PartyLink force-false grab and earlier Story cursor behavior are superseded by #133. The36 raw-form `importer="keep"` sidecars are already present. Audio shutdown branch is diagnostic only: retain its finding; do not clear caches or null streams as a fake fix. No PR merged, branch rewritten or existing checkout switched.

Recent30minute system query found15USB-C SD Card Reader pipe-stall events; prior actual disconnect at09:18 remains unresolved. Both mount UUIDs match, encrypted image path matches, private ownership enabled. This does NOT establish transport stability or post-disconnect asset integrity. Private-art production/injection/native acceptance remains BLOCKED. No remount/repair/deletion. Internal after sparse materialization about18.96GiB, under19GiB heavy-start guard; no heavy import/export/capture.

Completed next increment: all25PartyLink tests passed after correcting the independently reproduced stale forced-false grab expectation; real localhost/two-process inputs exercised. Four tiny source-bound Godot checks passed: save defaults/restore, replay roundtrip/tamper rejection,16stale scene acknowledgments,23combat/Story/replay checks. Three harness-only failures are retained. Owner saves unchanged. These are NOT native BattleScene, earned Story, physical LAN or visual acceptance. See FOCUSED_VALIDATION.json.

NEXT after external gate clears: recheck BOTH transport/mount/resource identities and recent faults; rehash existing private art/receipts and decode existing media. Inspect completed Emberfemale and interrupted Embermale files without replacing them. Then implement/verify guarded private asset-to-BattleScene binding using the existing clips and authoritative runtime phase clock. No rebaking/re-recording completed assets. Do not rebake completed sources. Revalidate existing Emberfemale candidate and Embermale partial only after storage is stable.

All human art/paired runtime/RC2/release gatesfalse. Current corrected inventory remains2/24move IDs perbody,36clips total; no new art/effects from reconciliation. Native BattleScene/packaged/device acceptance PENDING. No exact-candidate CI or paid Actions initiated. Existing #133CI does not validate this candidate.

Current final internal free is about18.92GiB;19GiB heavy-start guard is short by about0.08GiB even before any extra workload forecast. No heavy import/capture/Blender run is authorized by this measurement. Owner must stabilize the existing USB path; no new infrastructure, cleanup, remount or repair performed. No automatic messages to other chats. The existing Cursor worker process was present but original43source snapshots remained unchanged during this run; candidate operates only on preserved committed heads.

Focused source validation command (fresh output required): `python3 tools/integration/run_preserved_engine_checks.py --godot /Applications/Godot.app/Contents/MacOS/Godot --output outputs/integration-checks/engine_NEXT`. Do not rerun its successful checks unless dependent source changes. Source/TS runtime logs are in this candidate outputs/integration-checks; no typecheck claim (installed Node TS transformation). No source/art commit was pushed to either original PR.

Stationary recheck:13samples/123.28s held mount UUIDs, but3recentUSBpipe-stalls and the real existing production preflight still FAILS at18.912GiB. See RESOURCE_GATE.json. No fresh private-art output integrity or native acceptance claimed. Compiled PartyLink execution independently reproduced2bad source-path lookups; repaired without removing any content assertions.25/25compiled tests now pass. Supplemental installed TypeScript6strict checks pass; pinned5/exact-candidateCI pending. No downloads, paidActions or physicalLAN claim.
