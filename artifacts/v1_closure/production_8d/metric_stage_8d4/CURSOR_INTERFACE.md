# Shipping paired-contact calibration request

The owner selected the measured 8D-3 Ember male camera **for offline art framing only**. Source-metre actor placements in 8D-4 are editable art compositions derived from evaluated torso support planes. They do not define gameplay spacing. `RUNTIME_PAIRED_CONTACT_VERIFIED=false`.

No Cursor branch was merged, rewritten or messaged. This is a source-backed interface request for its engineering owner.

## Required runtime contract

For each fighter, both bodies and both facings, expose one versioned, source-hash-bound observation at the **same authoritative combat frame**:

- Gameplay root in pixels, facing and actor identity; state/move/throw owner and resolved frame clock.
- Actual model/rig root, source-to-Godot axis conversion, armature unit scale and immutable source/GLB hashes.
- SubViewport size, display scale/offset, camera projection/size, camera world transform, rig world transform and rig-to-camera transform.
- A common physical stage anchor or an explicitly authorized actor-to-actor metric transform, including depth. A separate local zero root in each viewport is insufficient.
- The intended relationship among source sole plane, model presentation root, gameplay collision bottom and stage floor.
- Any supported form/presentation changes to the above, with source identities and explicit applicability.

The current retained v3 observations already expose the private camera chains. The missing authority is the **relationship between the two private 3D worlds**, not another guessed conversion constant. Preserve all accepted gameplay spacing, collision, damage, timing, escape and Story rules.

## Measured incompatibilities to retain

`art_source/staging/metric_8d4/inputs_v1.json` records all 18 native body-camera scales and 576 verified chains from run `39910149332`. Ember/Juno native scales differ by 3.7% male and 7.6% female. Native held roots use `(24*facing, -8)` pixels, while both private rig roots can remain zero. The 8D-3 holder's projected sole residual is 32.60–38.45 pixels below collision bottom. Do not normalize these away by scaling or translating a complete model.

## Acceptance interface

Replaying a captured frame must reproduce source points through the full transform chain. Moving an opponent must change measured 3D surface distance; changing depth along a projection nullspace must remain distinguishable despite coincident pixels. Saved source and imported runtime surfaces need matched witnesses, including feet, palm pads and the intended opponent surface. Unreachable/interpenetrating restraints remain explicit failures.

Offline reference scenes retain separate static placement anchors, original anatomy/rest/actions and new action namespaces, so later calibrated wrappers can be applied without regenerating the original art. No shipping paired-contact or human visual gate may pass from offline measurements alone.
