# Existing-action playback correction — original-art production still blocked

Recovered source: `5410dd2256ed1f2bb9651ad1ea9b1cb1333fcd84`, draft PR123
stacked on122. All42worktrees are retained. No Cursor lane, original rig, source
action, camera take, move value, collision rule, Story save or archive changed.

## Reproduced runtime defect and correction

The model's explicit `play_clip()` API routed charge/walk/run/fall/shield through
IDLE. Other standalone action previews were routed through attack state selection,
which marked the manual AnimationPlayer as MoveRunner-owned despite there being
no MoveRunner. Existing release/recovery actions consequently stayed at time0.

The existing state-to-clip resolver now selects the appropriate neutral state.
Standalone action previews retain their requested action and advance on the
presentation clock. Real Fighter state calls still use their resolved gameplay
clock; canonical idle/form selection and terminal acting retain their existing
paths. No new animation, gameplay resolver or character design was introduced.

An isolated headless Godot check exercised the actual model API/controller with
existing Kaia/Rook saved action keys, both bodies, and a fixture skeleton. The
same fixture against a read-only overlay of5410dd22 reproduced wrong charge
selection and stalled release/recovery. The corrected API selects charge and
advances release/recovery to0.2seconds after12steps. Freeze, neutral aliases,
terminal clocks and subsequent gameplay clock ownership also passed.

This is a **clock-control regression**, not imported character-mesh playback,
ordinary combat, new original art, paired contact, or visual/human acceptance.
Initial isolated-autoload fixture failures are retained privately and are not
counted as successful regressions.

`ExistingClipPlayback8D4.gd` prepares the corresponding real-model regression. It
parses, but its model-loading execution is **NOT RUN**: storage preflight failed.
Do not infer a full-model or roster pass from the lightweight fixture.

## Original-art and visual status

No8D-4Blender scene or animated character GLB was produced. Official checksumGET
and DMGHEAD still return403challenge over verified TLS. Installed3.3.1 is
unchanged. Package checksum, signature, ARM64 compatibility and installation
footprint remain unverified. No large download, mount or installation occurred.

Internal free space fell from19.379GiB to approximately17.319GiB during this
continuation; background storage variation is not an attributed test allocation.
The controller-only fixture files total only kilobytes and load no model/texture
assets. Heavy production remains blocked below22GiB AFTER compatible installation;
the18GiB plus forecast guard was not lowered. No additional deletion or cleanup.

The private comparison reuses the original design sheet and existing native
watch stills atc0db89d0, respecting the superseding collectible/hair directives.
Those stills predate this playback fix. They do not show paired grip, release,
recovery or validated floor support. No new proprietary asset was uploaded.

Remaining: one genuine original paired performance with resistance, disengagement,
support exchange and recovery; two-actor skeletal export; deformed skin/contact,
reach and floor measurements; native playback/visual comparison; separate shipping
projection calibration. The existing25-framehold and joint fixtures do not close
these requirements. Do not expand the remaining reference cases yet.

Exact-head CI is NOT RUN. Private Actions stays disabled and undispatched; no paid
job or public art upload. All human/paired-contact/roster/release gates remainFALSE.
