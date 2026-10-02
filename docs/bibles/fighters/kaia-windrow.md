# Kaia Windrow — Production Bible V1
## The Skyflow Duelist

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
- **Fantasy:** The spectrum's aerial mediator; movement becomes pressure control.
- **Archetype:** Aerial Spacer
- **Color / cosmic identity:** GREEN `#2FCB88`
- **Movement verbs:** flow, curve, float, redirect, spiral, glide, balance
- **Shape language:** arcs, airfoils, ribbons, crescents, open negative space
- **Material language:** Elemental wind/air/pressure humanoid with human facial structure formed from flowing green currents and pressure surfaces rather than ordinary skin.

## Movement physics authority
| Weight | Run | Dash | Air | Jump | Fall |
|---:|---:|---:|---:|---:|---:|
| 96 | 274.4 | 411.6 | 246.4 | 644.8 | 1728 |

For the seven spectrum fighters, these are the current accepted numeric baselines from the master bible. Animation must express them without silently retuning them.

## State-by-state motion language

| State | Required Kaia Windrow expression |
|---|---|
| idle | Never fully gravity-bound; control surfaces respond subtly; calm centered breath. |
| walk | Smooth transfer with less vertical bounce than Ember/Juno. |
| run | Long flowing stride; upper body composed. |
| dash | Lean → airfoil alignment → low pressure-driven horizontal sweep. |
| turnaround | Redirects momentum through curved footwork and ribbon arc rather than stopping. |
| jump / double jump | Most elegant takeoff; double jump uses pressure ring/wind step. |
| air drift | Banks visibly into horizontal drift; limbs/ribbons function as control surfaces. |
| fast fall | Airfoils collapse; body streamlines downward. |
| landing | Bleeds vertical energy sideways into a spiral/step. |
| shield / dodge | Flows around danger; guard remains calm and open. |
| hurt-light | Balance disturbed. |
| hurt-heavy | Flow breaks; control surfaces lose alignment. |
| launch / tumble | Ribbons/control surfaces flare uncontrolled before Kaia recovers aerodynamic organization. |
| KO | Wind structures unravel and settle rather than exploding. |
| victory | Currents orbit and then settle around a centered stance. |

## Aura / transformation language

| State | Visual/motion requirement |
|---|---|
| BASE | gentle current |
| CHARGED | pressure rings |
| SURGE | airfoils open |
| ASCENDANT | larger current ribbons |
| SUPER | eye of a controlled storm |

## Attack-pose law
Every attack must look as if it could only belong to **Kaia Windrow**.

Use the six-beat grammar:
```text
intent → anticipation → acceleration → contact → follow-through → recovery
```

The body must communicate the state before the HUD/VFX does.

- **Smear/deformation family:** wind ribbon arc
- **Movement/audio family:** air pressure + cloth/control-surface flutter
- **Voice rhythm:** calm but decisive; never blandly peaceful

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
Canonical prismatic story form: wind remains the binding medium carrying the six other Essences.

## Story puppet expression
### Yin-controlled / Black Puppet
Wind circulation is dragged inward and becomes eerily still; one green current survives.

### Yang-controlled / White Puppet
Wind is forced into perfect repeated spirals and rigid flow lines.

For the seven spectrum fighters, puppet masks belong here—not on the base roster.

## Audio / camera / hitstop
- Normal attacks: no camera cut; micro impulse only where justified.
- Heavy attacks: brief directional impulse aligned to impact.
- Supers: authored push/FOV/angle allowed, but return before gameplay ambiguity.
- 2–8 player PartyLink: gameplay readability overrides cinematic takeover.
- Hitstop must freeze a deliberate attacker pose and a deliberate victim pose.
- Exact hitstop frames remain move-data authority.

## Acceptance question
> **Does Kaia own aerial flow without looking weightless or passive?**

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
