# CURSOR MASTER — ANIME AGGRESSORS CHARACTER/MOVEMENT AUTHORITY FULL-COMPLETION AUDIT + IMPLEMENTATION
## Use nine fighter production bibles and machine-readable manifests as the new animation/movement authority

Repository:
`gunnchOS3k/anime-aggressors`

Existing draft PR:
`#118 — v4: dual-form power-archetype roster`

Verified prompt-authoring state:
- PR open / draft / mergeable
- head `93cf7150e2a958f73391d654489ee4c9121d9ae0`
- branch `v4/dual-form-power-roster`
- exact-head workflow runs returned as completed success at verification time
- do not merge
- do not create a replacement PR unless #118 has been closed/merged by the owner before runtime

## 0. Source authority

The package to ingest contains:
```text
source/ANIME_AGGRESSORS_COMPLETE_CHARACTER_MOVEMENT_ANIMATION_BIBLE_V1.md

docs/bibles/fighters/
  ember-vale.md
  rook-ironside.md
  juno-spark.md
  kaia-windrow.md
  nix-calder.md
  orion-vell.md
  vesper-nyx.md
  yin.md
  yang.md

data/bibles/
  FIGHTER_BIBLE_INDEX.json
  animation_inventory_v1.json
  movement_profiles_v1.json
  state_to_animation_contract_v1.json
  reaction_profiles_v1.json
  aura_profiles_v1.json
  presentation_profiles_v1.json
  puppet_essence_story_states_v1.json
  production_gate_matrix_v1.json
  animation_audit_row.schema.json

artifacts/audit/
  CURRENT_REPO_BASELINE_2026-09-29.json
```

Copy these into the repository under the same relative paths if they are not already present.
Do not silently edit the source master to make implementation easier.

The master defines intended finished product, not current completion.

---

# 1. Non-negotiable truth model

Use these terminal statuses:

```text
MISSING
PROCEDURAL_FALLBACK
AUTHORED_WIP
AUTHORED_CANDIDATE
PASS_WITH_EVIDENCE
REQUIRES_HUMAN
NOT_APPLICABLE
```

Rules:

1. A procedural runtime clip is **not** authored completion.
2. A clip file existing is **not** visual readability pass.
3. An animation playing is **not** human feel pass.
4. A male/female body variant does not require duplicate motion libraries.
5. Never change gameplay frame data merely to make an animation easier.
6. G6/G8/G9 remain human-owned exactly as defined in the gate manifest.
7. No fabricated Pixel or human evidence.

---

# 2. First action: exhaustive read-only audit

Before mutation, refresh:
```bash
git fetch --all --prune
git rev-parse HEAD
git rev-parse origin/main
```

Verify the working branch is the current #118 head or safely rebase/update only if the owner playbook permits.
Never reset a dirty owner checkout.

Read and inventory:

```text
game-godot/scripts/fighters/fighter_states.gd
game-godot/scripts/fighters/fighter_state_machine.gd
game-godot/scripts/fighters/fighter_animator.gd
game-godot/scripts/visual/fighter_animation_controller.gd
game-godot/scripts/visual/runtime_move_resolver.gd
game-godot/data/fighters/*
game-godot/data/moves/*
art_source/animation/**
game-godot/assets/characters/**
```

For every spectrum fighter and every authority slot in `animation_inventory_v1.json`, resolve:

```text
fighter_id
slot_id
category
current gameplay state(s)
current move_id if applicable
current runtime clip
current source path
current status
current evidence
fallback path
```

Write:

```text
artifacts/animation_authority_v1/CURRENT_ANIMATION_STATE_AUDIT.json
artifacts/animation_authority_v1/CURRENT_ANIMATION_STATE_AUDIT.csv
artifacts/animation_authority_v1/FIGHTER_COVERAGE_MATRIX.json
artifacts/animation_authority_v1/MOVE_TO_CLIP_MATRIX.json
artifacts/animation_authority_v1/STATE_TO_CLIP_MATRIX.json
artifacts/animation_authority_v1/PROCEDURAL_FALLBACK_CENSUS.json
```

Do not mutate until this census is committed or at least saved in the worktree.

Expected baseline to verify, not blindly trust:
- 22 current action directories per spectrum fighter
- WAVE_A manifest: 98 entries, 0 authored complete, 98 `PROCEDURAL_FALLBACK`
- 24 current move IDs per spectrum fighter
- current state machine has 51 named states
- current master prose says 23 move entries but live repo includes `back_air`

If live data differs, record the live truth.

---

# 3. Authority discrepancy: back_air

Do NOT delete `back_air`.

Policy:
```text
back_air = RETAIN_CURRENT_REQUIRED_EXTENSION
```

Audit it exactly like every other aerial.

Document the mismatch between master prose and live move data.
Do not rewrite history.

---

# 4. Complete the state vocabulary

The target is all required authority slots, not merely the existing 14-action Wave A set.

Implement state coverage for:

## Locomotion / traversal
idle_primary, idle_secondary, idle_long, walk_start, walk_loop, walk_stop, run_start, run_loop, run_stop, dash_start, dash_loop, dash_stop, skid, turnaround, crouch_start, crouch_hold, crouch_end, jump_squat, jump, short_hop_visual, double_jump, fall, fast_fall, land_soft, land_hard, platform_drop

## Ledge / platform
edge_warning, ledge_teeter, ledge_grab, ledge_hang, ledge_getup, ledge_roll, ledge_jump, ledge_attack

## Defense / evasion
shield_start, shield_hold, shield_hit, shield_stun, shield_break, spot_dodge, roll_forward, roll_backward, air_dodge_neutral, air_dodge_forward, air_dodge_back, air_dodge_up, air_dodge_down, tech_in_place, tech_forward, tech_back, pratfall

## Damage / reactions
hurt_light_front, hurt_light_back, hurt_heavy, hitstop_pose, hitstun_ground, launch_horizontal, launch_vertical, tumble, ground_bounce, wall_bounce, knockdown, ko, respawn

## Grab / throw
grab_startup, grab_active, grab_whiff, grab_hold, pummel, throw_startup, throw_release

## Aura
aura_charge, aura_ready, aura_burst_startup, aura_burst_active, aura_burst_recovery, aura_super_transform

## Current 24 moves
jab_1, jab_2, jab_finisher, forward_tilt, up_tilt, down_tilt, dash_attack, heavy_attack, neutral_air, forward_air, back_air, up_air, down_air, neutral_special_projectile, side_special, up_special_recovery, down_special, grab, throw_forward, throw_back, throw_up, throw_down, aura_charge_move, aura_burst_move

## Presentation
match_intro, character_select_idle, character_select_confirm, taunt_1, taunt_2, victory, defeat, results_idle, story_dialogue_neutral, story_dialogue_intense

The authority has 111 slots per identity. Some slots may intentionally alias/parameterize, but every alias must be explicit and semantically justified.

Target unique authored clip scale remains roughly 90–100 per gameplay identity, consistent with the master.

---

# 5. Eliminate coarse runtime lies

Current coarse state fallbacks are allowed only as temporary runtime continuity.

Examples that must be audited/fixed:
```text
RUN → walk
DOUBLE_JUMP → jump_rise
ATTACK_STARTUP/ACTIVE/RECOVERY → generic jab
SPECIAL_STARTUP/ACTIVE/RECOVERY → generic special
HITSTUN → hurt_heavy
EDGE_WARNING/LEDGE_TEETER → ledge_hang
DODGE_RECOVERY → idle
```

The finished runtime resolver must prefer:

```text
exact move clip
> exact state clip
> documented semantic alias
> temporary fallback
```

A temporary fallback increments:
```text
PROCEDURAL_FALLBACK_COUNT
```
and prevents G2/G3 from passing for that fighter.

---

# 6. Fighter-specific authored motion

For each fighter, read its production bible before authoring clips.

Required motion laws:

```text
Ember  = combustion
Rook   = mass
Juno   = current
Kaia   = flow
Nix    = structure
Orion  = vectors
Vesper = uncertainty
Yin    = reduction
Yang   = definition
```

Do not solve roster coverage by applying one shared locomotion animation with different VFX.

For every spectrum fighter, ensure at least five differentiation axes differ from every other fighter:
```text
center of gravity
stride length
acceleration read
air posture
landing style
turnaround
idle rhythm
anticipation length
follow-through
defense posture
hurt reaction
smear style
aura growth
camera response
audio footprint
```

Generate:
```text
artifacts/animation_authority_v1/ROSTER_DIFFERENTIATION_MATRIX.json
```

---

# 7. Animation authoring standard

Use the existing canonical skeleton/control rig and current authored-animation pipeline.

Each authored clip needs:
```text
source provenance
fighter identity
slot/action id
runtime clip id
duration frames
key-pose intent
interpolation mode
loop rule
root-motion rule
hitbox/frame sync notes
VFX event markers where applicable
SFX event markers where applicable
human approval=false
```

Use 60 Hz gameplay timing.

Visual animation may deliberately hold poses.

Use the six-beat attack grammar:
```text
INTENT
ANTICIPATION
ACCELERATION
CONTACT
FOLLOW-THROUGH
RECOVERY
```

Allow screen-space deformation:
- hand/foot scale
- limb stretch
- torso squash
- perspective cheating
- power-specific smear geometry

Collision remains canonical.

---

# 8. Move-by-move completion

For each current spectrum fighter, audit all 24 live move IDs:

```text
jab_1
jab_2
jab_finisher
forward_tilt
up_tilt
down_tilt
dash_attack
heavy_attack
neutral_air
forward_air
back_air
up_air
down_air
neutral_special_projectile
side_special
up_special_recovery
down_special
grab
throw_forward
throw_back
throw_up
throw_down
aura_charge
aura_burst
```

Each must resolve to its own authored clip or a specifically justified authored shared clip.

No:
```text
all attacks → jab
all specials → special
all throws → throw
```

Write:
```text
artifacts/animation_authority_v1/MOVE_ANIMATION_COMPLETION_7X24.json
```

Required:
```text
SPECTRUM_MOVE_SLOT_COUNT=168
UNRESOLVED_MOVE_ANIMATION_COUNT=0
```

This is slot resolution, not automatic human-quality approval.

---

# 9. Full reaction coverage

Implement and validate:
```text
hurt_light_front
hurt_light_back
hurt_heavy
hitstop_pose
hitstun_ground
launch_horizontal
launch_vertical
tumble
ground_bounce
wall_bounce
knockdown
shield_break
grabbed
thrown
ko
```

Each fighter's reaction must follow its bible.

G6 remains human-owned.

---

# 10. Aura and elemental identity

For all seven spectrum fighters implement visible:
```text
BASE
CHARGED
SURGE
ASCENDANT
SUPER
```

Not just brightness changes.

The body is elemental with human facial structure.
Do not revert to ordinary shuffled skin-tone bodies.

Base roster:
```text
MASK=false
```

Masks belong to story puppets.

---

# 11. Puppet variants

For each of the seven spectrum fighters:
```text
NORMAL
YIN_CONTROLLED_BLACK_PUPPET
YANG_CONTROLLED_WHITE_PUPPET
```

Puppet state should primarily modify:
- secondary motion
- timing feel
- material/VFX
- facial/eye state
- mask
- story presentation

Do not duplicate the full gameplay move library unless technically necessary.

Yin puppet:
- individuality subtracted
- inward drag
- original hue pulse remains

Yang puppet:
- timing imposed into unnatural symmetry
- over-clean trajectories
- original imperfection remains

Generate:
```text
artifacts/animation_authority_v1/PUPPET_VARIANT_MATRIX.json
```

---

# 12. Essence progression / Prismatic Gray

Implement story-facing presentation states:
```text
0 Essence — BASE
1 Essence — SACRIFICE_POWER_BOOST
2 Essences — POST_3V2_IMBALANCE_LEVELING
4 Essences — LAST_TWO_PILLARS_APPROACH
6 Essences — GRAY_PRISMATIC_CHROMATIC
```

For the root Kaia story and future anchor routes, do not flatten progression into a simple damage multiplier.

Motion/VFX must visibly accumulate resonance.

Competitive Prismatic forms preserve:
```text
frame data
hitboxes
movement
damage
knockback
recovery
```

Story variants may use Essence-enhanced mechanics.

---

# 13. Yin and Yang implementation track

The nine production bibles include Yin and Yang.

Their numeric movement/frame baselines are intentionally not canonically approved.

Do not invent final numbers and label them approved.

Instead create:
```text
game-godot/data/fighters/yin.json
game-godot/data/fighters/yang.json
game-godot/data/moves/yin.json
game-godot/data/moves/yang.json
```
only if the architecture is ready to host them.

Any new numeric values must be:
```text
status=TUNING_CANDIDATE
owner_approved=false
```

Implement their complete state/animation architecture and motion identity:
```text
Yin  = reduction / inward collapse
Yang = definition / outward expansion
```

Keep:
```text
COSMIC_BOSS_VERSION
PLAYABLE_BALANCED_VERSION
```
as distinct gameplay contracts.

Do not allow boss-only unfair movement in ranked/playable form.

If full playable data cannot truthfully be tuned in this run, terminal state is:
```text
YIN_PLAYABLE_TUNING=REQUIRES_HUMAN
YANG_PLAYABLE_TUNING=REQUIRES_HUMAN
```
while animation/state infrastructure can still be complete.

---

# 14. Male/female parity

For all seven spectrum identities:
- one canonical gameplay rig per fighter identity;
- male/female same action IDs;
- same skeleton/bone contract;
- same VFX/hitbox sockets;
- same root-motion assumptions;
- same gameplay reach envelope.

Run every completed clip against both presentations.

Required:
```text
BODY_VARIANT_ANIMATION_COMPAT_14_OF_14=true
```

No cosmetic hitbox changes.

---

# 15. Readability harness

Build automated capture/testing for:
```text
silhouette
3-frame anticipation/contact/recovery
VFX-off
25%-scale
grayscale
duplicate-fighter
freeze-frame contact
```

Automation may create evidence.

Automation may NOT claim the human visual judgment.

Write:
```text
artifacts/animation_authority_v1/READABILITY_EVIDENCE_INDEX.json
```

---

# 16. Pixel exact-head physical proof

After digital gates are clean and only after safe disk remediation if needed:

Build exact #118 head Android APK.

Pixel rules:
- inspect installed signer
- inspect candidate signer
- use `adb install -r`
- no uninstall
- no `pm clear`
- no wipe
- no downgrade
- stop on signer mismatch

Capture a controlled state review for all seven spectrum fighters:
```text
idle
walk
run
dash
turn
jump
double jump
fast fall
soft/hard land
shield
dodge
ledge
hurt light/heavy
launch/tumble
grab/throw
aura
at least one normal/tilt/aerial/special
KO
victory
```

Also:
```text
male/female compatibility
Black Puppet
White Puppet
Kaia 0/1/2/4/6 Essence states
```

Yin/Yang Pixel review only if runtime/playable candidate exists.

G7 may pass with physical evidence.
G8/G9 remain false until owner review.

---

# 17. CI / validators

Add:
```text
tools/animation_authority/validate_bible_index.py
tools/animation_authority/audit_state_coverage.py
tools/animation_authority/audit_move_clip_resolution.py
tools/animation_authority/audit_fallbacks.py
tools/animation_authority/audit_body_variant_compat.py
tools/animation_authority/audit_puppet_variants.py
tools/animation_authority/audit_aura_states.py
```

CI must fail when:
- required authority slot disappears;
- current move has no clip resolution;
- `PROCEDURAL_FALLBACK` is relabeled as authored;
- male/female skeleton/action contract diverges;
- base fighter accidentally uses puppet mask;
- frame/hitbox data changes without explicit gameplay-data change record.

Do not weaken existing CI.

---

# 18. Completion gates

For each spectrum fighter:

```text
G0_DATA_COMPLETE
G1_RIG_COMPLETE
G2_STATE_COVERAGE_COMPLETE
G3_MOVE_ANIMATION_COMPLETE
G4_HITBOX_FRAME_SYNC_COMPLETE
G5_VFX_SFX_COMPLETE
G6_VISUAL_READABILITY_COMPLETE=false until human review
G7_PIXEL_PHYSICAL_PASS
G8_HUMAN_FEEL_PASS=false
G9_FINAL_ART_APPROVED=false
```

Roster digital target:
```text
SPECTRUM_STATE_AUTHORITY_7_OF_7=true
SPECTRUM_MOVE_ANIMATION_168_OF_168=true
BODY_VARIANT_ANIMATION_COMPAT_14_OF_14=true
PROCEDURAL_FALLBACK_COUNT=0
UNMAPPED_RUNTIME_STATE_COUNT=0
UNRESOLVED_MOVE_ANIMATION_COUNT=0
PUPPET_VARIANT_7_OF_7=true
ESSENCE_PROGRESSION_0_1_2_4_6_PASS=true
```

Yin/Yang:
```text
BIBLE_COMPLETE=true
STATE_ARCHITECTURE_COMPLETE=true
PLAYABLE_TUNING_APPROVED=false unless owner actually approves
```

---

# 19. PR / safety policy

- Continue existing #118.
- Do not merge.
- One mutation agent/worktree for Anime repository.
- Read-only audit subagents may run in parallel.
- No force-push.
- No secrets.
- No owner-tree reset.
- No stale #106 generated-art resurrection.
- Preserve PartyLink 2/4/6/8.
- Preserve 161-move/combat regressions.
- Preserve body-variant gameplay parity.

---

# 20. Required final report

Return:

```text
PR=118
HEAD=
BASE_MAIN=

AUTHORITY_PACKAGE_INSTALLED=
FIGHTER_BIBLES=9/9
AUTHORITY_SLOT_COUNT_PER_IDENTITY=111

CURRENT_STATE_COUNT=
CURRENT_MOVE_COUNT_PER_SPECTRUM_FIGHTER=
CURRENT_PROCEDURAL_FALLBACK_COUNT=

EMBER_G0_G9=
ROOK_G0_G9=
JUNO_G0_G9=
KAIA_G0_G9=
NIX_G0_G9=
ORION_G0_G9=
VESPER_G0_G9=
YIN_STATUS=
YANG_STATUS=

SPECTRUM_STATE_AUTHORITY_7_OF_7=
SPECTRUM_MOVE_ANIMATION_168_OF_168=
BODY_VARIANT_ANIMATION_COMPAT_14_OF_14=
PROCEDURAL_FALLBACK_COUNT=
UNMAPPED_RUNTIME_STATE_COUNT=
UNRESOLVED_MOVE_ANIMATION_COUNT=
PUPPET_VARIANT_7_OF_7=
ESSENCE_PROGRESSION_0_1_2_4_6_PASS=

ANDROID_EXACT_HEAD_BUILD=
PIXEL_SIGNER_SAFETY_PASS=
PIXEL_ANIMATION_REVIEW_PACKET_READY=

HUMAN_VISUAL_READABILITY_PASS=false
HUMAN_FEEL_PASS=false
FINAL_ART_APPROVED=false
MERGE_AUTHORIZED=false
```

If all automatable spectrum animation authority work is complete:
```text
NEXT_ANIME_ACTION=OWNER_FULL_ROSTER_MOVEMENT_FEEL_REVIEW
```

If fixable digital gaps remain:
```text
NEXT_ANIME_ACTION=FIX_REMAINING_ANIMATION_AUTHORITY_GAPS
```

Do not stop merely because the old 14-action Wave A passes.
Do not stop merely because a generic fallback plays.
The new authority is the complete state/move/motion bible.
