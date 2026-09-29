# Rook Ironside — Production Bible V1
## The Walking Bastion

**Authority class:** Creative + animation + movement production authority  
**Scope:** base/playable presentation, male/female body presentation, movement, attacks, reactions, aura, story variant behavior, and relevant unlock form.  
**Implementation truth:** this defines the target; it does not claim current repository completion.

## Production law
Anime Aggressors treats a fighter as a **motion identity**, not a mesh plus attacks.

The house style is:
```text
ANIME CHARACTER DESIGN
+ 3D CEL-SHADED MODELS
+ 2D-LIKE KEY-POSE TIMING
+ PLATFORM-FIGHTER READABILITY
+ MARVEL-VS-CAPCOM-SCALE EXAGGERATION
+ CARTOON SQUASH / STRETCH
```

Gameplay simulation is 60 Hz. Visual poses may intentionally hold 2–3 simulation frames when that improves readability.

Every expressive attack follows:
```text
INTENT → ANTICIPATION → ACCELERATION → CONTACT → FOLLOW-THROUGH → RECOVERY
```

On major contact, combine:
```text
strong silhouette + pose exaggeration + hitstop + hit spark + impact SFX + defender reaction + selective camera impulse
```

Never hide weak posing under particles.

### Readability tests
Every final candidate must pass:
- silhouette test;
- 3-frame anticipation/contact/recovery test;
- VFX-off test;
- 25%-scale test;
- grayscale test;
- duplicate-fighter test;
- freeze-frame contact test.


## V4.5 visual continuity
- Base roster uses **human facial structure but elemental material completion**. Do not shuffle ordinary human skin tones as the body material.
- Male/female are visual presentations of the same soul/personality/moveset/animation set.
- Base roster does **not** use the mask direction.
- Masks are reserved for **Black Puppet / Yin-controlled** and **White Puppet / Yang-controlled** story variants.
- Every spectrum fighter needs NORMAL, YIN-CONTROLLED BLACK PUPPET, and YANG-CONTROLLED WHITE PUPPET presentation states.
- Story Essence progression uses 0 → 1 → 2 → 4 → 6 collected Essences. At 6, the anchor reaches the Gray Prismatic/Chromatic transformation.
- Prismatic Gray means all seven colors held without one dominating; it does not mean colorless emptiness.


## Identity
- **Fantasy:** A fortress that decided to move.
- **Archetype:** Armored Bruiser
- **Color / cosmic identity:** ORANGE `#F47A20`
- **Movement verbs:** brace, plant, compress, carry, crush, anchor, advance
- **Shape language:** blocks, columns, layered strata, heavy circles at joints, broad low triangles
- **Material language:** Elemental stone/earth/forged-plate body with tectonic seams and shock-ring joints; human facial structure carved/formed from the element rather than ordinary skin.

## Movement physics authority
| Weight | Run | Dash | Air | Jump | Fall |
|---:|---:|---:|---:|---:|---:|
| 125 | 238 | 357 | 193.6 | 570.4 | 1944 |

For the seven spectrum fighters, these are the current accepted numeric baselines from the master bible. Animation must express them without silently retuning them.

## State-by-state motion language

| State | Required Rook Ironside expression |
|---|---|
| idle | Wide stance; visible weight settling; loaded asymmetry; small armor compression instead of fidgeting. |
| walk | Every step shows weight transfer; no foot sliding; obvious hip/shoulder counter-rotation. |
| run | Step 1 commitment → step 2 mass moving → step 3 unstoppable. |
| dash | Short armored charge, never an athletic sprint. |
| turnaround | Visual deceleration and compression before redirecting. |
| jump / double jump | Deep compression; takeoff looks expensive; no graceful floating. |
| air drift | Limited correction; limbs prepare for impact rather than agility. |
| fast fall | Mass reasserts itself; limbs tuck into a descending bastion shape. |
| landing | Roster's heaviest landing; two-foot plant or tectonic shock pose. |
| shield / dodge | Receives force physically; plates lock; dodge is short armored lean/shift. |
| hurt-light | Mass resists; head/shoulder acknowledges. |
| hurt-heavy | Armor separates slightly; tectonic seams flare. |
| launch / tumble | Mass fights trajectory; body rotates as one heavy unit rather than ragdoll flailing. |
| KO | Building collapse: knees fail first → torso mass follows → armor loses alignment. |
| victory | Plates settle and lock; minimal celebration communicates grounded confidence. |

## Aura / transformation language

| State | Visual/motion requirement |
|---|---|
| BASE | dark basalt/metal |
| CHARGED | seams glow |
| SURGE | joint rings activate |
| ASCENDANT | plates restack/compress |
| SUPER | living fortress silhouette |

## Attack-pose law
Every attack must look as if it could only belong to **Rook Ironside**.

Use the six-beat grammar:
```text
intent → anticipation → acceleration → contact → follow-through → recovery
```

The body must communicate the state before the HUD/VFX does.

- **Smear/deformation family:** mass compression / rock debris arc
- **Movement/audio family:** dense low-frequency armor/stone impacts
- **Voice rhythm:** minimal words, grounded confidence

## Male / female presentation contract
- Same soul, personality, move IDs, frame data, gameplay reach, action IDs, VFX sockets, hitbox sockets and root-motion assumptions.
- Different facial/body presentation may alter silhouette proportions only inside the canonical gameplay envelope.
- The body remains elemental rather than ordinary human-skin completion.
- No animation library duplication by body variant.

## Rig/deformation contract
One canonical gameplay rig for this identity.
Required compatible controls:
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

Visual deformation may exceed collision geometry; gameplay collision may not.

## Required authority slots
This fighter inherits the machine-readable inventory in `data/bibles/animation_inventory_v1.json`.

Total authority slots: **111**.

The master bible's “roughly 90–100 authored clips” target refers to authored production scale; this manifest enumerates every required state/move/presentation slot, including slots that may intentionally alias or be parameterized.

## 24-move current-game compatibility note
The master bible text enumerates 23 move-specific entries and omits `back_air`; the live repository currently has **24** move IDs per spectrum fighter and includes `back_air`.

V1 production policy:
```text
back_air = RETAIN_CURRENT_REQUIRED_EXTENSION
```
Do not remove it during animation cleanup. If the owner later wants the master prose revised, update the master separately and explicitly.

## Prismatic / unlock expression
Other essences become material states—molten plate, conductive stone, cryo-strata, gravity compression, phase armor—while movement remains mass.

## Story puppet expression
### Yin-controlled / Black Puppet
Armor silhouette is swallowed inward; joints become quiet void gaps; one orange seam remains.

### Yang-controlled / White Puppet
Armor becomes over-perfect, symmetric, white-latticed and mechanically timed.

For the seven spectrum fighters, puppet masks belong here—not on the base roster.

## Audio / camera / hitstop
- Normal attacks: no camera cut; micro impulse only where justified.
- Heavy attacks: brief directional impulse aligned to impact.
- Supers: authored push/FOV/angle allowed, but return before gameplay ambiguity.
- 2–8 player PartyLink: gameplay readability overrides cinematic takeover.
- Hitstop must freeze a deliberate attacker pose and a deliberate victim pose.
- Exact hitstop frames remain move-data authority.

## Acceptance question
> **Can the player feel Rook's mass before Rook attacks?**

## Final production gates
```text
G0 DATA COMPLETE
G1 RIG COMPLETE
G2 STATE COVERAGE COMPLETE
G3 MOVE ANIMATION COMPLETE
G4 HITBOX / FRAME SYNC COMPLETE
G5 VFX / SFX COMPLETE
G6 VISUAL READABILITY COMPLETE
G7 PIXEL PHYSICAL PASS
G8 HUMAN FEEL PASS
G9 FINAL ART APPROVED
```

No lower gate implies a higher gate.
