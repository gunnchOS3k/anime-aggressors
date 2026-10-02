# Vesper Nyx — Production Bible V1
## The Phase Weaver

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
- **Fantasy:** A spatial trickster whose greatest weapon is making the opponent trust the wrong moment.
- **Archetype:** Phase Trickster
- **Color / cosmic identity:** VIOLET `#B73CFF`
- **Movement verbs:** misdirect, offset, vanish, reappear, delay, slip, fracture
- **Shape language:** asymmetry, broken diagonals, negative space, split tails, offset doubles, partial circles
- **Material language:** Elemental void/phase humanoid with human facial structure formed from violet spatial material, negative space and ghost offsets rather than ordinary skin.

## Movement physics authority
| Weight | Run | Dash | Air | Jump | Fall |
|---:|---:|---:|---:|---:|---:|
| 88 | 266 | 399 | 215.6 | 607.6 | 1728 |

For the seven spectrum fighters, these are the current accepted numeric baselines from the master bible. Animation must express them without silently retuning them.

## State-by-state motion language

| State | Required Vesper Nyx expression |
|---|---|
| idle | Never completely stable; occasional hand ghost, shadow delay or cowl offset. |
| walk | Quiet and predatory; unexpected shoulder/foot leads. |
| run | Path remains readable while exact location feels uncertain. |
| dash | Short phase displacement with competitively readable start/end. |
| turnaround | Brief offset silhouette through the pivot. |
| jump / double jump | Low visual effort; double jump is local phase correction. |
| air drift | Trajectory is honest but secondary geometry suggests adjacent positions. |
| fast fall | Ghost positions collapse into the lowest trajectory and body follows. |
| landing | Feet and ghost geometry arrive slightly out of phase. |
| shield / dodge | Minimal guard; dodge is phase slip. |
| hurt-light | Body flickers but receives hit honestly. |
| hurt-heavy | Phase coherence collapses into one forced position. |
| launch / tumble | Multiple ghost positions stretch then collapse onto actual launched body. |
| KO | All offsets collapse to one silhouette, then void seams fail. |
| victory | Multiple possible silhouettes appear, then only the chosen Vesper remains. |

## Aura / transformation language

| State | Visual/motion requirement |
|---|---|
| BASE | small void seams |
| CHARGED | edge ghosts |
| SURGE | negative-space cuts |
| ASCENDANT | secondary offset fragments |
| SUPER | silhouette disagrees with itself |

## Attack-pose law
Every attack must look as if it could only belong to **Vesper Nyx**.

Use the six-beat grammar:
```text
intent → anticipation → acceleration → contact → follow-through → recovery
```

The body must communicate the state before the HUD/VFX does.

- **Smear/deformation family:** phase afterimage
- **Movement/audio family:** phase flutter + reversed transient + spatial delay
- **Voice rhythm:** dry, playful, ambiguous

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
Each phase echo may carry a different Essence color while phase/void remains primary.

## Story puppet expression
### Yin-controlled / Black Puppet
Offsets are swallowed until almost no secondary identity remains; one violet pulse survives.

### Yang-controlled / White Puppet
Offsets become exact repeated copies with imposed white symmetry.

For the seven spectrum fighters, puppet masks belong here—not on the base roster.

## Audio / camera / hitstop
- Normal attacks: no camera cut; micro impulse only where justified.
- Heavy attacks: brief directional impulse aligned to impact.
- Supers: authored push/FOV/angle allowed, but return before gameplay ambiguity.
- 2–8 player PartyLink: gameplay readability overrides cinematic takeover.
- Hitstop must freeze a deliberate attacker pose and a deliberate victim pose.
- Exact hitstop frames remain move-data authority.

## Acceptance question
> **Does Vesper feel deceptive without becoming unreadable/unfair?**

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
