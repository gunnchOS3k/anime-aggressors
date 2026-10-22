# 8B — saved original action candidates; visual acceptance pending

Draft PR123 remains stacked on122, branch
`release/anime-v1-dialogue-and-elemental-performance`.
This is a working source/runtime increment, **not completed production acting**.
All human art, gameplay, balance, device and release gates remain false.

## Saved source and runtime correspondence

The owner explicitly approved the exact two public-repository artifacts.
[Run39733087497](https://github.com/gunnchOS3k/anime-aggressors/actions/runs/39733087497)
passed at `cc2b3a5a555aeb22fc8eb7510bd7702a28975aad`, using Blender4.0.2.
It saved **18 new preserved-rig copies with540WIPactions**, reopened each,
and evaluated15340source frames against the runtime keys. Maximum matrix
component error was0.000003994. Original meshes, rest bones, weights and
existing action curves were checked unchanged. All18 original Blender files
remain unchanged; all18 original BASE GLB hashes match the exports.

Each rig has30new actions (15categories × two facings): acquire, whiff,
holder hold, victim restraint, victim escape, holder recovery, landing,
four throw releases and four directional victim reactions. Source identifiers
are `ANI08B_WIP_<clip>`; these are individually directed regional pose scores
baked onto the actual rig, **not final artist-approved performances**.
No Kaia/Juno curve was copied as the roster's acting.

The established22-bone boundary keys21pose bones plus pelvis position;
Root remains static. Throw release remains at gameplay frame zero, with
anticipation in hold and existing runtime clocks controlling playback.
No original model, geometry, proportions, skin weights, source library,
GLB, damage, frame data, collision, launch, Perfect Guard or Party rule changed.

[ROSTER_18_MATRIX.json](ROSTER_18_MATRIX.json) lists every exact original path,
original/saved hash,30saved action IDs and runtime mapping. The saved copy for
each entry is `saved_sources/<fighter>/<body>/candidate_8b.blend` in the source
artifact. Corresponding text is installed at
`game-godot/data/animation/grab_acting_8b/<fighter>_<body>.json`.

| Fighter | Male saved actions | Female saved actions | Visual/fidelity approval |
|---|---:|---:|---|
| Ember |30|30|Pending|
| Rook |30|30|Pending|
| Juno |30|30|Pending|
| Kaia |30|30|Pending|
| Nix |30|30|Pending|
| Orion |30|30|Pending|
| Vesper |30|30|Pending|
| Yin |30|30|Pending|
| Yang |30|30|Pending|

## Runtime changes

Reciprocal ownership selects distinct holder/victim loops and mirrored actions.
An old acquisition runner cannot overwrite an ongoing hold. Actual mash escape
selects victim acting while preserving immediate movement/attack control.
Throw reactions follow the real launch vector; landing uses actual floor/state
and the existing landing clock. Missing/unverified exports retain honest fallback
status rather than claiming authored source.

A real release-callback comparison found holders selecting `grab_whiff` after
mash escape. The correction selects saved `grab_recovery(_left)` within the
unchanged GRAB_WHIFF state. In the pilot, all four legal immediate victim
counterattacks still landed and interrupted the holder's recovery normally.
[RECOVERY_CORRECTION.json](RECOVERY_CORRECTION.json) retains the exact baseline,
failed observer/setup attempts, corrected result and source hashes.

## Verification scope

The earlier12routing fixtures and36roster/body/facing fixtures used empty
in-memory clips and remain labelled fixtures. They are not saved acting evidence.
The actual-export pilot passed16public directional throws plus4mixed-body
escapes using real saved tracks, real model resources and no animation injection.

The full180interaction saved-export run and affected form/cleanup results are
recorded separately in [VALIDATION_SUMMARY.json](VALIDATION_SUMMARY.json) when
complete. Read its exact source IDs and completion flags; a partial run is not a
pass. Explicit position/idle fixtures are not active-CPU matches, earned Story,
KO, native visual or human acceptance. Shutdown resource warnings are retained.

[PRODUCTION_MANIFEST_39733087497.json](PRODUCTION_MANIFEST_39733087497.json)
records saved/reopened source correspondence; local validation also matches
original/saved provenance, complete21-bone pose tracks, static Root contract,
finite normalized keys, action IDs, frame-zero releases and all18 GLB hashes.
Source binary hashes were checked remotely. No source binary was downloaded
or rehashed on the Mac.

## Owner playable review

From the current worktree run:

```sh
tools/v1_closure/play_party_review.command kaia-windrow --body female --opponent juno-spark
```

Use any canonical fighter ID and either body; append `--local` for two players.
The existing launcher isolates review saves. A/D move, W jumps, J attacks,
K specials, L shields, U grabs, I dodges. While holding, direction + J throws;
without a direction the existing default throw applies. Mash ordinary attack,
jump or grab as the victim. Review the hold/grip, four releases, victim reaction,
landing and interruption at normal speed. Repeat with both bodies and facings.
Use the existing Full/Balanced/Reduced options to assess readability. A native
VFX-disabled paired art comparison remains pending; effects do not establish
physical contact quality. No new native recording is supplied below
the storage reserve. Existing movies retain their original source IDs.

## Production work still required

- All18 rigs need paired mesh/hand/wrist contact authoring at the actual held
  offsets, with real gameplay-scale visual review. Projected wrists versus a
  hurt rectangle are diagnostics, not proof of skin contact or visual approval.
- Ember/Kaia/Nix/Orion/Vesper contain clipped desired hand targets; the retained
  maximum residual is up to0.02805m. No anatomy was stretched to conceal this.
  Resolve the exact pose/paired staging through original source edits.
- Independent deforming hair/cloth/armor follow-through remains unavailable on
  the existing Head-bound accessory setup. Add justified source controls,
  weighting and corresponding export support on each original body, preserving
  the character sheets; head/neck keys alone are not secondary-motion closure.
- Boots/weighted soles, support exchanges, visible silhouette, anticipation,
  force and natural recovery still need representative native art review.
  Existing floor/projection defects are not declared repaired by this increment.
- New dedicated8B KO/interrupted body acting and form-specific original acting
  remain incomplete. Existing hurt/KO/interrupt gameplay cleanup is preserved.
  Shared BASE export compatibility is not authored boss/form acceptance.
- No native-device, sustained frame-performance, physical-controller, LAN,
  earned campaign/Convergence or final OVA acceptance is inferred here.

## Artifact preservation and storage

[REMOTE_ARTIFACT_RECEIPT.json](REMOTE_ARTIFACT_RECEIPT.json) records approved
payload hashes, IDs and retention. Source artifact12406037776 contains the18new
saved Blender copies; runtime artifact12406187575 contains text/receipts.
Both expire **January20,2027**. Retain the saved source artifact before expiry
when storage permits; it is not a permanent source backup. Original source
rigs and all33worktrees remain in place.

Only4.48MiB of runtime archive was downloaded, expanding to24.91MiB of text;
no .blend, GLB or native export was generated locally. Internal free remains
about12GiB, below18GiB plus allocations: no local binary art production,
large recording, platform export, deletion or worktree relocation. Existing
verified external-archive receipts were reused without new copies/deletion.
