# 8B — source foundation; saved acting remains blocked

Prepared source checkpoint `0895437b` on
`release/anime-v1-dialogue-and-elemental-performance`, draft PR123 stacked on122.
This increment does **not** claim completed original character acting.
There are **zero newly saved Blender actions** and no installed8B runtime exports.

## Implemented support

- Reciprocal holder/victim animation selection and mirrored clip names, with
  explicit fallback/fixture/authored provenance diagnostics.
- Correct looping for hold presentation. The old grab runner can no longer
  replace an ongoing hold with its earlier acquisition pose.
- Real mash-escape presentation selection that yields immediately to movement,
  new attacks, hurt, KO, reset and match end. No new control lock or gameplay timer.
- Conditional directional throw-victim reactions and real landing presentation
  using the existing hurt/hitstop/landing clocks.
- Optional rig-specific overlays are admitted only after saved-action and
  source/runtime verification, matching identity/body and source identifiers.
  Unverified pose files cannot masquerade as saved acting.

The original8A ownership, damage, hitboxes, throws, Perfect Guard, Party forms,
aura defaults and inputs remain authoritative. No character model, scale,
geometry, weight or original source action was replaced.

## Original source prepared

`art_source/animation/grab_acting_8b/score_v1.json` contains nine individually
directed regional pose scores: holder restraint/preparation, victim resistance,
escape, acquisition/whiff, four directional releases, four airborne reactions,
and supported landing/recovery. Each fighter has its own pose values and intent;
this is not a Kaia/Juno curve copied across the roster.

The existing offline rig/sole boundary bakes30candidate clips per actual rig
(15actions × two facings), across all18 rigs. These540pose candidates are
**not540saved actions**. Desired hand targets are clipped by anatomical reach in
some Ember/Kaia/Nix/Orion/Vesper samples; exact residuals are retained per body.
No limb was stretched or moved to conceal that limitation. Physical contact,
acting quality and supporting-foot appearance still need actual source/native review.

[ROSTER_18_MATRIX.json](ROSTER_18_MATRIX.json) contains all18 exact source paths,
original hashes, planned action identifiers and runtime files. Every row currently
has source-save, new acting import, paired authored contact, character-sheet
fidelity, native evidence and human approval incomplete/false.

| Fighter | Male rig | Female rig | New saved acting |
|---|---|---|---|
| Ember | Score + routing support | Score + routing support | 0; blocked |
| Rook | Score + routing support | Score + routing support | 0; blocked |
| Juno | Score + routing support | Score + routing support | 0; blocked |
| Kaia | Score + routing support | Score + routing support | 0; blocked |
| Nix | Score + routing support | Score + routing support | 0; blocked |
| Orion | Score + routing support | Score + routing support | 0; blocked |
| Vesper | Score + routing support | Score + routing support | 0; blocked |
| Yin | Score + routing support | Score + routing support | 0; blocked |
| Yang | Score + routing support | Score + routing support | 0; blocked |

## Actual validation

-12lifecycle/routing fixtures passed, then36roster/body/facing configurations
  passed. The body models are real existing GLBs; the injected test animations
  are empty in-memory fixtures. They prove routing/looping/interruption only.
- Existing GrabLifecycle8A15, ThrowOwnership39 and PartyGrabInterruption9 passed.
- All18 original Blender files retain their protected Git identity. The pure
  source bake and Python syntax checks passed without running local Blender.
- No new Blender save/reopen, new runtime export/import, native visual/device
  test or sustained frame-performance acceptance occurred. Existing evidence
  keeps its original source IDs. Shutdown resource warnings remain in the logs.

Character-sheet fidelity, meaningful secondary hair/cloth motion, original KO
acting, full form retargeting, paired hand/body contact and floor appearance
remain production work. No fixture result or pose count closes those gates.

## Concrete remote production operation awaiting approval

The existing Authored Animation Production workflow now has an opt-in
`grab_acting_8b` job on Ubuntu24.04. It uses the established Blender-action→JSON
boundary, saves **new copies** of all18 original rigs, reopens every saved file,
and checks original geometry/rest/weights/action preservation and evaluated
source/runtime correspondence. Blender exceptions fail the job, and a separate
validator requires the exact complete18-rig manifest.

[ARTIFACT_APPROVAL_PLAN.json](ARTIFACT_APPROVAL_PLAN.json) lists the exact18 input
files/hashes, all proposed saved-copy paths and540action identifiers. Proposed
outputs are two GitHub Actions artifacts, retained90days:

1. `grab-acting-8b-saved-sources-<SHA>`:18new `.blend` copies containing original
   meshes/materials/weights/actions plus the proposed acting actions.
2. `grab-acting-8b-runtime-<SHA>`:18text animation exports and a hash/verification
   manifest. Only this bounded text artifact would be downloaded internally,
   with a32MiB cap. Source binaries would remain remote until storage permits.

The repository is public. GitHub says signed-in users with repository read
access can download artifacts:
https://docs.github.com/en/actions/how-tos/manage-workflow-runs/download-workflow-artifacts
No credentials/secrets, source replacement, merge, release, tag or deployment
is part of this operation. It is nevertheless additional external exposure of
the new source copies and acting candidates.

**Automatic approval review rejected workflow dispatch** because that exact
artifact payload/exposure was not explicitly authorized. No job was dispatched,
no new source binaries were uploaded, and no alternate tool or workaround was
used. Remote production requires the owner's explicit artifact-upload approval.

Internal free is about12GiB, below18GiB plus allocations. Local Blender saves,
large renders, movies and native exports remain blocked. The APFS archive UUID
was confirmed and existing receipts reused; no originals were deleted or moved.

## Next execution

After explicit approval, verify the reviewed production-code hashes, dispatch
the prepared18-rig job, retain its exact SHA/run/artifact IDs, and require all18
saved/reopened passes. Then validate/install only the bounded text overlays and
run real paired contact/throw/body/facing tests. Do not promote the current
pose candidates or routing fixtures to authored acting in the meantime.

All art, gameplay, balance, native/device and release approval gates remain false.
