# Nix Calder — Production Bible V1
## The Cryolattice Architect

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
- **Fantasy:** A tactical controller who builds order into the battlefield.
- **Archetype:** Control Tank
- **Color / cosmic identity:** BLUE `#3F86F7`
- **Movement verbs:** measure, place, lock, brace, construct, contain, advance
- **Shape language:** facets, grids, lattices, hexagonal/triangular crystal, vertical walls
- **Material language:** Elemental ice/crystal humanoid with human facial structure sculpted from blue cryolattice material rather than ordinary skin.

## Movement physics authority
| Weight | Run | Dash | Air | Jump | Fall |
|---:|---:|---:|---:|---:|---:|
| 118 | 252 | 378 | 198 | 589 | 1890 |

For the seven spectrum fighters, these are the current accepted numeric baselines from the master bible. Animation must express them without silently retuning them.

## State-by-state motion language

| State | Required Nix Calder expression |
|---|---|
| idle | Extremely controlled; minimal wasted motion; hands evaluate space. |
| walk | Measured chosen steps. |
| run | Organized stride even at speed. |
| dash | Controlled frost slide with explicit stop point. |
| turnaround | Sharp deliberate pivot. |
| jump / double jump | Compact takeoff; structured air pose. |
| air drift | Movement is deliberate and geometry-oriented rather than floaty. |
| fast fall | Crystal facets align into a downward spear/column profile. |
| landing | Crystal/frost geometry briefly organizes beneath feet. |
| shield / dodge | Calculated guard; dodge uses minimum necessary displacement. |
| hurt-light | Structure flexes. |
| hurt-heavy | Crystalline geometry fractures visibly. |
| launch / tumble | Crystal pieces trail in ordered fragments before snapping back to body logic. |
| KO | Lattice fractures from outer structures inward. |
| victory | A precise crystal construction forms and resolves around Nix. |

## Aura / transformation language

| State | Visual/motion requirement |
|---|---|
| BASE | small facets |
| CHARGED | lattice expands |
| SURGE | mantle grows |
| ASCENDANT | major crystal structures |
| SUPER | center of a geometric frozen system |

## Attack-pose law
Every attack must look as if it could only belong to **Nix Calder**.

Use the six-beat grammar:
```text
intent → anticipation → acceleration → contact → follow-through → recovery
```

The body must communicate the state before the HUD/VFX does.

- **Smear/deformation family:** crystal construction streak
- **Movement/audio family:** crystal tick + ice compression
- **Voice rhythm:** measured, analytical

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
Other essences become construction materials inside Nix's lattice language.

## Story puppet expression
### Yin-controlled / Black Puppet
Crystal detail is subtracted into dark planes; one blue facet remains.

### Yang-controlled / White Puppet
Crystal becomes over-symmetric white geometry with perfectly repeated growth.

For the seven spectrum fighters, puppet masks belong here—not on the base roster.

## Audio / camera / hitstop
- Normal attacks: no camera cut; micro impulse only where justified.
- Heavy attacks: brief directional impulse aligned to impact.
- Supers: authored push/FOV/angle allowed, but return before gameplay ambiguity.
- 2–8 player PartyLink: gameplay readability overrides cinematic takeover.
- Hitstop must freeze a deliberate attacker pose and a deliberate victim pose.
- Exact hitstop frames remain move-data authority.

## Acceptance question
> **Does Nix look like a tactical builder/controller rather than generic ice mage?**

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
