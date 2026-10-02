# Ember Vale — Production Bible V1
## The Living Furnace

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
- **Fantasy:** A combustion martial artist who turns pressure into relentless forward offense.
- **Archetype:** Rushdown Striker
- **Color / cosmic identity:** RED `#EF2B1F`
- **Movement verbs:** ignite, lunge, drive, burst, chase, plant, re-ignite
- **Shape language:** wedges, forward diagonals, gauntlet circles, vent slits, furnace core
- **Material language:** Elemental flame/heat body with charred ceramic/obsidian structure, thermal seams, furnace core and ignition gauntlets; human facial structure without ordinary human skin completion.

## Movement physics authority
| Weight | Run | Dash | Air | Jump | Fall |
|---:|---:|---:|---:|---:|---:|
| 100 | 294 | 441 | 224.4 | 620 | 1800 |

For the seven spectrum fighters, these are the current accepted numeric baselines from the master bible. Animation must express them without silently retuning them.

## State-by-state motion language

| State | Required Ember Vale expression |
|---|---|
| idle | Weight slightly forward; hands never fully relaxed; furnace core rises/falls with breath; small shoulder vents; impatience without jitter. |
| walk | Aggressive stalking step; decisive foot contact; upper body already aimed at opponent. |
| run | Torso pitched forward; arms remain combat-ready; rear-foot heat impulse reinforces acceleration. |
| dash | Compress → furnace flash → violent forward wedge → controlled catch step. Never just 'run faster.' |
| turnaround | Hard heel plant with a short heat skid. |
| jump / double jump | Self-propelled takeoff; double jump uses directional combustion pulse with knee compression. |
| air drift | Aerial motion remains driven by visible propulsion rather than float. |
| fast fall | Vents cut and body knifes downward with a short heat wake. |
| landing | Aggressive momentum catch; hard landing adds heat flare, never a generic superhero kneel. |
| shield / dodge | Offensive guard posture; shoulders forward, gauntlets on centerline; combustion-assisted slip dodge. |
| hurt-light | Angry interruption. |
| hurt-heavy | Core flickers/vents; force disrupts ignition rhythm. |
| launch / tumble | Flame trail breaks into unstable heat fragments while body remains readable. |
| KO | Vents fail → core dims → forward body tension disappears. |
| victory | Re-ignite from dim core into a controlled flare; confidence, not uncontrolled rage. |

## Aura / transformation language

| State | Visual/motion requirement |
|---|---|
| BASE | small furnace glow |
| CHARGED | thermal seams activate |
| SURGE | gauntlets and vents open |
| ASCENDANT | heat crown and stronger body distortion |
| SUPER | opened humanoid furnace |

## Attack-pose law
Every attack must look as if it could only belong to **Ember Vale**.

Use the six-beat grammar:
```text
intent → anticipation → acceleration → contact → follow-through → recovery
```

The body must communicate the state before the HUD/VFX does.

- **Smear/deformation family:** heat wedge / flame stretch
- **Movement/audio family:** heat crackle + ignition thump
- **Voice rhythm:** direct, impatient, committed

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
Six Essence colors appear as secondary ignition states while combustion remains the movement source.

## Story puppet expression
### Yin-controlled / Black Puppet
Flame is starved inward; heat sound collapses; one red pulse remains.

### Yang-controlled / White Puppet
Flame becomes unnaturally geometrical and perfectly repeated; one dark imperfection remains.

For the seven spectrum fighters, puppet masks belong here—not on the base roster.

## Audio / camera / hitstop
- Normal attacks: no camera cut; micro impulse only where justified.
- Heavy attacks: brief directional impulse aligned to impact.
- Supers: authored push/FOV/angle allowed, but return before gameplay ambiguity.
- 2–8 player PartyLink: gameplay readability overrides cinematic takeover.
- Hitstop must freeze a deliberate attacker pose and a deliberate victim pose.
- Exact hitstop frames remain move-data authority.

## Acceptance question
> **Does every movement feel like controlled combustion?**

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
