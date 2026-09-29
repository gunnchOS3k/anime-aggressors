# Yin — Production Bible V1
## The Infinite Quiet

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
- **Fantasy:** A cosmic principle of reduction that seeks peace by subtracting difference.
- **Archetype:** Cosmic Nullifier / Control
- **Color / cosmic identity:** BLACK `#0A0A0D`
- **Movement verbs:** absorb, settle, fold, collapse, still, erase, draw inward
- **Shape language:** inward spirals, negative space, collapsed circles, soft asymptotic curves, void apertures
- **Material language:** Black elemental/cosmic being with readable human facial structure but no ordinary human skin; a small white seed must remain visible.

## Movement physics authority
Yin/Yang numeric movement/frame values are **not canonically approved in the master bible**. Prototype values must be labeled `TUNING_CANDIDATE`, measured in play, and never silently promoted to final authority.

For the seven spectrum fighters, these are the current accepted numeric baselines from the master bible. Animation must express them without silently retuning them.

## State-by-state motion language

| State | Required Yin expression |
|---|---|
| idle | Uses less effort than anyone; unnervingly quiet with almost no secondary motion. |
| walk | Silent and economical. |
| run | Not athletic running; space shortens around Yin. |
| dash | Destination darkens → distance collapses → Yin is there. Distinct from Vesper deception. |
| turnaround | Space folds around the pivot; body seems to arrive at the new facing rather than spin. |
| jump / double jump | Gravity seems to stop insisting. |
| air drift | Controlled motion by collapsing path length. |
| fast fall | Space below compresses and Yin settles into it. |
| landing | Almost no impact sound; nearby ambience briefly disappears. |
| shield / dodge | Attacks are reduced/absorbed rather than met with brute guard. |
| hurt-light | Impact is swallowed. |
| hurt-heavy | Absorption threshold is exceeded; white seed becomes more visible. |
| launch / tumble | Cosmic boss may resist normal launch; playable version must visibly obey knockback fairness. |
| KO | Void aperture closes around core, leaving the white seed last. |
| victory | The arena quiets and motion/sound reduce around Yin. |

## Aura / transformation language

| State | Visual/motion requirement |
|---|---|
| BASE | quiet black field with white seed |
| CHARGED | trails/sound shorten |
| SURGE | nearby geometry visually collapses inward |
| ASCENDANT | large null field |
| SUPER | toward-zero cosmological reduction |

## Attack-pose law
Every attack must look as if it could only belong to **Yin**.

Use the six-beat grammar:
```text
intent → anticipation → acceleration → contact → follow-through → recovery
```

The body must communicate the state before the HUD/VFX does.

- **Smear/deformation family:** trail deletion / space fold
- **Movement/audio family:** ambience removal + sub-bass pressure
- **Voice rhythm:** quiet, economical, almost never raised

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
Not a Prismatic Gray unlock form; Yin is a cosmic endpoint unlocked after seven Gray routes.

## Story puppet expression
### Yin-controlled / Black Puppet
N/A controller archetype

### Yang-controlled / White Puppet
If story requires Yang influence on Yin, treat as exceptional cosmological event rather than normal puppet skin.

For the seven spectrum fighters, puppet masks belong here—not on the base roster.

## Audio / camera / hitstop
- Normal attacks: no camera cut; micro impulse only where justified.
- Heavy attacks: brief directional impulse aligned to impact.
- Supers: authored push/FOV/angle allowed, but return before gameplay ambiguity.
- 2–8 player PartyLink: gameplay readability overrides cinematic takeover.
- Hitstop must freeze a deliberate attacker pose and a deliberate victim pose.
- Exact hitstop frames remain move-data authority.

## Acceptance question
> **Does Yin subtract reality rather than merely use black VFX?**

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
