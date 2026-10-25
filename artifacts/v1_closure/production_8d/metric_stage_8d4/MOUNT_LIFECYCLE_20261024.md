# Private-art production stopped after confirmed USB storage interruption

Investigation source: `5b3f88a160276c95d25271f8fa202f9da70b9b19`, draft PR #123 stacked on #122. Cursor PR #133 and its worktree remain untouched. No heavy production, artwork regeneration, image mounting, detachment or repair was performed during this attempt.

The owner-remounted image initially matched the recorded private APFS UUID, encrypted backing image and ownership requirements. Internal free space was 22.808 GiB, private free space 58.958 GiB and archive free space 336.079 GiB. The existing final production receipt was readable. The volume disappeared again before complete fresh integrity verification.

## Observed cause chain

All times below are October 24, 2026, America/Chicago (UTC−05:00), from macOS unified logs.

| Time | Actual event |
| --- | --- |
| 22:26:25.289826 | Kernel: USB-C SD Card Reader “hardware connection lost.” |
| 22:26:25.294462 | Kernel: outer archive `disk5` “media is not present.” |
| 22:26:25.297037 | APFS begins unmounting `gunnchOS-Archives`. |
| 22:26:25.326948 | `diskimagesiod` forces the nested private-art volume to unmount. |
| 22:26:25.338088 | Disk-image I/O terminates because of an unrecoverable I/O error. |
| 22:26:32.146833 | Archive reappears mounted; it disconnects again at 22:26:33. |
| 22:26:37.067480 | Archive reappears again. The encrypted image remains absent. |

The earlier 22:14–22:18 interval contains the same SD-reader disconnection pattern. This explains why later checks found the archive mounted while the encrypted image was missing: those snapshots missed the archive's transient interruption.

The observed trigger is loss of the external USB storage transport. These logs do **not** establish which port, reader, cable, power, OS/controller or software condition caused that loss. They do not justify blaming Blender, the native viewer, a particular application or an art-production cleanup handler.

APFS also logged unfinished transactions during forced unmount. Existing completion receipts remain valid historical evidence, but file integrity must be checked again before further production. No corruption or successful repair is claimed.

## Cleanup and guard verification

- Reviewed the tracked local producer, encrypted-volume boundary and recovery utility. Their disk commands are read-only information queries; no detach/unmount/eject command was found.
- Before mount loss, reviewed private scratch production/review wrappers. Their signal cleanup targets owned child process groups. The disk-image helper had a separate process group. No production child was active during this reproduced loss. Private wrappers cannot currently be rehashed, and this audit does not cover every process on the Mac.
- The existing live guard rejects the absent private volume without creating a replacement workspace or launching production.
- Existing focused unmounted-volume/symlink regression: **PASS, one test**. No new synthetic tests were added. No successful historical long suites were repeated.
- Current full production preflight: **blocked**. A newly passing native or artistic result is not claimed.

Structured timeline, source-file hashes and preservation status: [MOUNT_LIFECYCLE_20261024.json](MOUNT_LIFECYCLE_20261024.json). Raw system logs and their SHA-256 receipt remain only in the local investigation directory, outside Git; they contain no copied character artwork and were not uploaded.

## Completed work retained, fresh readback pending

The prior 18 editable jab/heavy Blender sources, 36 animated GLBs, 18 native both-facing strike movies, nine phase sheets, private HTML gallery and Cursor handoff were already produced. The prior arm-reference exports and paired-release v10 comparison remain separate preserved outputs. Nothing was regenerated or deleted.

The final receipt was accessible at `/Volumes/gunnchos-private-art/output/roster_original_strikes_native_v1/FINAL_EXECUTION_RECEIPT.json` before the new loss. Complete artifact hashing and media decode verification after the repeated disconnect are **pending**, not passed. The private owner gallery is `/Volumes/gunnchos-private-art/output/roster_original_strikes_native_v1/OWNER_REVIEW.html`; it is unavailable while the image is unmounted.

## Exact safe continuation

1. Stabilize the existing SD-reader/USB connection. Keep heavy jobs paused. Do not repeatedly remount and retry, delete data or automatically repair/recreate the image.
2. Once the connection is stable, remount the **same** encrypted image once. Perform a bounded read-only continuity check of both mounts, including their filesystem device identity; stop on any disappearance or device change even if the mount returns.
3. Rehash existing source/export/media files against the saved receipts, verify the existing MP4s decode, and validate the private handoff. Preserve and report any mismatch; do not overwrite it or regenerate the roster.
4. Only after continuity, integrity and the unchanged production guards pass, recover the already-tested generic strike viewer into Git and resume the next actual art correction: Juno's heavy leading-hand closure using its own weighted controls, followed by the remaining roster acting work.

Later resources: internal 22.806 GiB, archive 336.043 GiB, private absent; 8 GiB RAM, 34% memory-pressure free, 7676.19 MiB swap used. Capacity alone cannot override a failed mount-stability gate.

`HUMAN_ART_APPROVED=false`, `RUNTIME_PAIRED_CONTACT_VERIFIED=false`, `RC2_READY=false`, `V1_0_0_RELEASE_AUTHORIZED=false`. No public art, paid execution, merge, release, tag or deployment.
