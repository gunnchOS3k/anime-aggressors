# Anime Aggressors — Canonical 3D Chibi Model Bible V1
## Build contract for modeling, rigging, materials, variants, export, animation compatibility, and runtime acceptance

**Authority:** Modeling/rigging production authority  
**Status:** Owner-approval candidate  
**Important:** Source-derived rules are retained. Numerical mesh/proportion budgets below are **PRODUCTION DECISION V1** recommendations created to turn the creative target into a repeatable pipeline.

---

# 1. Model philosophy

The model is not successful because it loads.

The model is successful when:
- the fighter is recognizable before VFX;
- the fighter moves according to its power identity;
- male/female presentation changes are obvious but competitively equivalent;
- close-up select/story views look intentional;
- gameplay view remains readable;
- rig, animation, VFX, sockets, and collisions remain compatible.

House style:

```text
ANIME CHARACTER DESIGN
+ STYLIZED 3D CHIBI MODEL
+ CEL SHADING
+ 2D-LIKE KEY-POSE TIMING
+ PLATFORM-FIGHTER READABILITY
+ EXAGGERATED SCREEN-SPACE POSES
+ CARTOON SQUASH / STRETCH
```

The models are 3D.
The pose thinking is 2D.

---

# 2. Chibi proportion standard

**PRODUCTION DECISION V1**

Target shared range:
- overall height: approximately 3.0–3.5 head units;
- head: large enough to preserve face/hair identity;
- hands: intentionally enlarged for attack readability;
- feet: intentionally enlarged for stance/landing readability;
- torso: compact, not box-shaped;
- limbs: long enough for martial silhouette and readable contact poses.

Archetype tuning:
- Rook: stockier/lower, roughly 2.8–3.1 heads;
- Nix: compact/sturdy, roughly 3.0–3.2;
- Ember/Orion/Yin/Yang: roughly 3.1–3.3;
- Juno/Kaia/Vesper: slightly longer/leaner, roughly 3.2–3.5.

These ratios may be adjusted after Pixel review, but the roster must stay in one family.

Do not use identical base bodies with only head swaps.

---

# 3. Geometry budget

**PRODUCTION DECISION V1**

Gameplay LOD0 target:
- 18k–35k triangles per fighter body including hair/costume, excluding transient VFX.

Review threshold:
- >45k triangles requires justification.

LOD1:
- 8k–18k triangles.

LOD2 / distant multiplayer:
- 3k–8k triangles.

Select/story close-up may use the same LOD0 or a higher-detail presentation mesh only if:
- it shares rig naming;
- it does not create a second animation-authority problem;
- performance remains acceptable.

Priority order:
1. face/hair silhouette;
2. hands;
3. major costume/material masses;
4. power structures;
5. secondary details.

Do not spend geometry on invisible micro-detail while face/hands remain crude.

---

# 4. Material and texture standard

Base fighters are elemental humanoids.

Do not use ordinary skin-tone completion as the default body material.

Recommended material stack:
- 1 body/base material;
- 1 costume/armor or structural material;
- 1 emissive/power mask;
- optional hair/secondary material;
- separate VFX materials.

Aim for 2–4 opaque/cel-shaded materials per fighter before VFX.

Texture guidance:
- 1K gameplay atlas is preferred where sufficient;
- 2K allowed for showcase fidelity;
- normal-map dependence should be limited because cel shading must carry form clearly;
- emissive masks must not wash out face structure.

Transparency:
- keep large transparent body surfaces rare;
- use separate VFX geometry for ghost/ribbon/phase effects when possible.

---

# 5. Cel-shading standard

Required visual layers:
- base color;
- primary shadow band;
- optional secondary accent/shadow;
- controlled emissive;
- optional outline/silhouette reinforcement where platform/GPU path supports it.

Lighting must preserve:
- face;
- hair;
- major body masses;
- original fighter color.

Yin:
- black must retain form through edge light, value separation, and white seed.

Yang:
- white must retain form through shadow lines, gold accents, and black seed.

---

# 6. Face and hair standard

All base/playable presentations require readable human facial structure.

Face minimum:
- readable eye shapes;
- brows or equivalent expression controls;
- nose plane;
- mouth;
- jaw/chin;
- cheek/forehead planes sufficient for cel shading.

Recommended expression controls:
- blink L/R;
- brow raise/lower;
- brow in/out;
- mouth open;
- smile/frown;
- jaw;
- optional eye aim.

Hair:
- model as large designed clumps, not individual strands;
- silhouette must remain recognizable at 25% scale;
- hair may be elemental material rather than ordinary hair where the fighter concept requires it.

---

# 7. Canonical gameplay skeleton

Use one canonical gameplay rig topology per fighter identity and compatible bone naming across male/female presentations.

Canonical deform skeleton:

```text
Root
Hips
Spine
Chest
Neck
Head

Shoulder_L
UpperArm_L
LowerArm_L
Hand_L

Shoulder_R
UpperArm_R
LowerArm_R
Hand_R

UpperLeg_L
LowerLeg_L
Foot_L
Toes_L

UpperLeg_R
LowerLeg_R
Foot_R
Toes_R
```

Required compatible sockets:

```text
hand_l
hand_r
foot_l
foot_r
chest
head
back
projectile_origin
aura_root
```

Power-specific extra controls may be added but may not rename or invalidate canonical gameplay bones/sockets.

---

# 8. Deformation controls

Required by the existing production authority:

```text
head scale
hand scale
foot scale
forearm stretch
upper-arm stretch
spine curve
shoulder offset
hip compression
torso squash
face/eye controls
power-structure controls
```

Screen-space deformation is allowed to exceed realistic anatomy.

Gameplay collision may not silently change because the visible mesh stretches.

---

# 9. Male / female mesh contract

Both presentations:
- bind to the same canonical gameplay skeleton;
- use the same action IDs;
- use the same animation library;
- use the same collision/hitbox definitions;
- use the same VFX sockets;
- remain within the gameplay reach envelope.

They must visibly differ in:
- face;
- hair;
- torso silhouette;
- shoulder/hip presentation;
- selected costume/armor shapes.

Automated acceptance:
- model path differs;
- mesh hash differs;
- render hash differs;
- silhouette image differs above defined threshold.

Human acceptance:
- a player can identify the form without looking at the UI toggle.

---

# 10. Collision and visual independence

Collision/hurtbox authority is gameplay data.

Visual mesh is presentation.

Therefore:
- exaggerated hands may extend visually beyond active hitbox;
- squash/stretch may move mesh without changing collision;
- hair/ribbons/orbit rings are usually non-colliding;
- variant body differences do not alter competitive reach.

No artist may resize combat authority implicitly by editing the mesh.

---

# 11. Animation compatibility

The source authority enumerates **111 semantic animation slots per fighter identity**, while the authored production target may be roughly 90–100 unique clips because documented aliases/parameterization can exist.

Current-game compatibility includes `back_air` as a required extension.

No body variant gets a duplicate full animation library.

Animation-resolution priority:

```text
exact move-specific authored clip
→ exact state authored clip
→ documented semantic alias
→ temporary procedural fallback
```

A procedural fallback preserves runtime continuity but does not count as authored completion.

Every expressive attack follows:

```text
INTENT
→ ANTICIPATION
→ ACCELERATION
→ CONTACT
→ FOLLOW-THROUGH
→ RECOVERY
```

---

# 12. Fighter build sheets

## Ember
Shape: wedges / forward diagonals / gauntlet circles / vents.  
Model emphasis: furnace core, gauntlets, swept combustion hair, forward posture.  
Material: charred ceramic/obsidian + thermal seams.  
Avoid: generic red body with flame particles.

## Rook
Shape: columns / strata / heavy circles / broad triangles.  
Model emphasis: layered armor plates, thick forearms, planted feet, face carved from material.  
Material: stone/forged plate.  
Avoid: literal cubes or toy bricks.

## Juno
Shape: forward diagonals / rails / forks / conductor nodes.  
Model emphasis: narrow body, lightning hair, conductive channels.  
Material: luminous electromagnetic body.  
Avoid: generic yellow speedster.

## Kaia
Shape: arcs / ribbons / crescents / airfoils / open negative space.  
Model emphasis: aerodynamic hair/current masses, flowing control surfaces.  
Material: green pressure/wind body.  
Avoid: rectangular torso or dependence on transparent VFX.

## Nix
Shape: facets / lattice / grids / vertical crystal.  
Model emphasis: intentional crystalline armor and construct surfaces.  
Material: blue cryolattice.  
Avoid: uncontrolled spike noise.

## Orion
Shape: circles / ellipses / nodes / vectors.  
Model emphasis: calm central body plus sparse orbit structures.  
Material: indigo gravity/cosmic surface.  
Avoid: covering model with spheres.

## Vesper
Shape: asymmetry / broken diagonals / negative space / offset doubles.  
Model emphasis: readable true body plus limited ghost offsets.  
Material: violet phase/void.  
Avoid: generic skeleton as final character.

## Yin
Shape: inward spirals / negative space / collapsed circles.  
Model emphasis: elegant black human-faced form, small white seed, inward taper.  
Material: black cosmic reduction field.  
Avoid: block body, skull shorthand, featureless black.

## Yang
Shape: radiating lines / perfect circles / hard-light grids / halos.  
Model emphasis: elegant white human-faced form, black seed, precise luminous geometry.  
Material: white/gold construction field.  
Avoid: generic angel, overexposed blob, block body.

---

# 13. Story-state model architecture

## Spectrum base
Normal unmasked fighter.

## Black Puppet
Prefer shared base mesh + control-state material/secondary geometry + mask, unless story readability requires additional mesh pieces.

## White Puppet
Prefer shared base mesh + imposed symmetry/material/secondary geometry + mask.

## Prismatic Gray
Prefer shared identity mesh with:
- neutralized base material;
- spectral accent system;
- identity-specific Essence manifestation;
- optional story-only power structures.

Do not create seven entirely unrelated Gray meshes that lose base identity.

## Yin / Yang boss vs playable
The same character identity may have:
- `COSMIC_BOSS` presentation contract;
- `PLAYABLE` competitive contract.

Boss scale/presentation may differ.
Playable collision and balance remain normalized.

---

# 14. Naming and export

Recommended naming:

```text
aa_ember_m_base.glb
aa_ember_f_base.glb
aa_ember_m_gray.glb
aa_ember_f_gray.glb

aa_rook_m_base.glb
...

aa_yin_m_base.glb
aa_yin_f_base.glb
aa_yang_m_base.glb
aa_yang_f_base.glb
```

Puppet presentation can be material/state driven when possible:

```text
fighter + body_variant + control_state
```

rather than duplicating every GLB.

Every export manifest should include:
- fighter ID;
- body variant;
- form/state;
- source art version;
- rig version;
- mesh hash;
- material version;
- export tool/version;
- Git SHA.

---

# 15. Runtime validation

Before model acceptance:

1. import into Godot;
2. verify canonical bones;
3. verify skin bind;
4. verify sockets;
5. verify animation playback;
6. verify variant resolver;
7. verify select preview;
8. verify battle spawn;
9. verify Story spawn;
10. verify results/victory;
11. verify mirror match;
12. verify Pixel performance.

Automated success does not imply visual approval.

---

# 16. Performance acceptance

On Pixel-class hardware:
- no model-import failure;
- no shader compile crash;
- no visible LOD pop in normal fight range;
- no ANR;
- stable memory behavior;
- VFX-off model still readable;
- 2-player fight must preserve silhouette;
- PartyLink/multi-fighter mode must have an explicit lower-detail path when needed.

---

# 17. Model review sheet

Every fighter review captures:
- front;
- side;
- back;
- 3/4;
- neutral idle;
- anticipation;
- contact pose;
- recovery;
- hurt;
- victory;
- male/female side-by-side;
- VFX-off;
- grayscale;
- 25% scale;
- in-match frame;
- select-screen frame.

Required final owner judgment:
- faithful to V4.5 identity;
- intentional chibi, not placeholder;
- face/hair/costume readable;
- male/female meaningful;
- not dependent on VFX;
- suitable for story close-up;
- suitable for gameplay.

G9 stays false until owner approval.
